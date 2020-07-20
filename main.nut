/*
 * This file is part of MagicGS, which is a GameScript for OpenTTD
 * Copyright (C) 2020 Sylvain Devidal
 *
 * MagicGS is free software; you can redistribute it and/or modify it 
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * MagicGS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with MagicGS; If not, see <http://www.gnu.org/licenses/> or
 * write to the Free Software Foundation, Inc., 51 Franklin Street, 
 * Fifth Floor, Boston, MA 02110-1301 USA.
 *
 */

require("version.nut");			// get SELF_VERSION
require("roadbuilder.nut");		// Creates a RoadBuilder instance

class MainClass extends GSController
{
	_loaded_data = null;
	_loaded_from_version = null;
	_init_done = null;

	constructor()
	{
		this._init_done = false;
		this._loaded_data = null;
		this._loaded_from_version = null;
	}
}

function MainClass::Start()
{
	this.Init();

	// Wait for company 0 to exists
	GSController.Sleep(1);

	while (true) {
		this.HandleEvents();

		if (!RoadBuilder.job_finished) {
			RoadBuilder.BuildRoads();
		}

		// GS must never stop, so we awake every 10 days
		GSController.Sleep(10 * 74);
	}
}

/*
 * This method is called during the initialization of your Game Script.
 * As long as you never call Sleep() and the user got a new enough OpenTTD
 * version, all initialization happens while the world generation screen
 * is shown. This means that even in single player, company 0 doesn't yet
 * exist. The benefit of doing initialization in world gen is that commands
 * that alter the game world are much cheaper before the game starts.
 */
function MainClass::Init()
{
	if (this._loaded_data != null) {
		if ("connected_towns" in this._loaded_data) RoadBuilder.connected_towns = this._loaded_data.connected_towns;
	}

	// Indicate that all data structures has been initialized/restored.
	this._init_done = true;
	this._loaded_data = null;
}

/*
 * This method handles incoming events from OpenTTD.
 */
function MainClass::HandleEvents()
{
	if (GSEventController.IsEventWaiting()) {
		local ev = GSEventController.GetNextEvent();
		if (ev == null) return;

		local ev_type = ev.GetEventType();
		switch (ev_type) {
			case GSEvent.ET_TOWN_FOUNDED: {
				// A new town was founded. We must connect it!
				GSLog.Info("A new town was founded. We must connect it!");
				RoadBuilder.job_finished = false;
				break;
			}
		}
	}
}

/*
 * This method is called by OpenTTD when an (auto)-save occurs. You should
 * return a table which can contain nested tables, arrays of integers,
 * strings and booleans. Null values can also be stored. Class instances and
 * floating point values cannot be stored by OpenTTD.
 */
function MainClass::Save()
{
	GSLog.Info("Saving data to savegame");

	if (!this._init_done) {
		return this._loaded_data != null ? this._loaded_data : {};
	}

	return { 
		connected_towns = RoadBuilder.connected_towns
	};
}

/*
 * When a game is loaded, OpenTTD will call this method and pass you the
 * table that you sent to OpenTTD in Save().
 */
function MainClass::Load(version, tbl)
{
	GSLog.Info("Loading data from savegame made with version " + version + " of the game script");

	// Store a copy of the table from the save game
	// but do not process the loaded data yet. Wait with that to Init
	// so that OpenTTD doesn't kick us for taking too long to load.
	this._loaded_data = {}
	foreach(key, val in tbl) {
		this._loaded_data.rawset(key, val);
	}

	this._loaded_from_version = version;
}