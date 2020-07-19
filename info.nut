/*
 * This file is part of MagicGS, which is a GameScript for OpenTTD
 * Copyright (C) 2020  Sylvain Devidal
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

require("version.nut");

class FMainClass extends GSInfo {
	function GetAuthor()		{ return "Sylvain Devidal"; }
	function GetName()			{ return "MagicGS"; }
	function GetDescription() 	{ return "MagicGS is a Game Script that connects towns at startup"; }
	function GetVersion()		{ return SELF_VERSION; }
	function GetDate()			{ return "2020-07-19"; }
	function CreateInstance()	{ return "MainClass"; }
	function GetShortName()		{ return "MAGI"; } // Replace this with your own unique 4 letter string
	function GetAPIVersion()	{ return "1.10"; }
	function GetURL()			{ return ""; }

	function GetSettings() {
		AddSetting({name = "max_distance_between_towns", description = "Maximum distance between towns. Take care with big values (>150)", easy_value = 128, medium_value = 128, hard_value = 128, custom_value = 128, flags = CONFIG_NONE, min_value = 16, max_value = 512});
		AddSetting({name = "max_connected_towns", description = "Maximum number of town to be connected to each town", easy_value = 5, medium_value = 5, hard_value = 5, custom_value = 5, flags = CONFIG_NONE, min_value = 1, max_value = 16});
	}
}

RegisterGS(FMainClass());
