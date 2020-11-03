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
	function GetDescription() 	{ return "MagicGS is a Game Script that connects towns"; }
	function GetVersion()		{ return SELF_VERSION; }
	function GetDate()			{ return "2020-07-21"; }
	function CreateInstance()	{ return "MainClass"; }
	function GetShortName()		{ return "MAGI"; }
	function GetAPIVersion()	{ return "1.10"; }
	function GetURL()			{ return ""; }
	function MinVersionToLoad() { return 1; }

	function GetSettings() {
		AddSetting({name = "max_connected_towns", description = "Maximum number of neighbor towns to be connected", easy_value = 5, medium_value = 5, hard_value = 2, custom_value = 5, flags = CONFIG_NONE, min_value = 1, max_value = 16});

		AddSetting({name = "connect_cities_to_cities", description = "----- Connect cities -----", easy_value = 1, medium_value = 1, hard_value = 1, custom_value = 1, flags = CONFIG_NONE + CONFIG_BOOLEAN});
		AddSetting({name = "max_distance_between_cities", description = "Maximum distance between cities", easy_value = 1024, medium_value = 512, hard_value = 256, custom_value = 512, flags = CONFIG_NONE, min_value = 20, max_value = 16384});
		AddSetting({name = "restrict_speed_city_to_city", description = "Restrict maximum road speed for city to city connection", easy_value = 0, medium_value = 0, hard_value = 1, custom_value = 0, flags = CONFIG_NONE + CONFIG_BOOLEAN});
		AddSetting({name = "speed_city_to_city", description = "Maximum road speed for city to city connection (km/h)", easy_value = 130, medium_value = 130, hard_value = 90, custom_value = 130, flags = CONFIG_NONE, min_value = 20, max_value = 255, step_size = 5});

		AddSetting({name = "connect_towns_to_cities", description = "----- Connect towns to cities -----", easy_value = 1, medium_value = 1, hard_value = 0, custom_value = 1, flags = CONFIG_NONE + CONFIG_BOOLEAN});
		AddSetting({name = "max_distance_between_towns_and_cities", description = "Maximum distance between towns and cities", easy_value = 512, medium_value = 256, hard_value = 128, custom_value = 256, flags = CONFIG_NONE, min_value = 20, max_value = 16384});
		AddSetting({name = "restrict_speed_town_to_city", description = "Restrict maximum road speed for town to city connection", easy_value = 0, medium_value = 1, hard_value = 1, custom_value = 1, flags = CONFIG_NONE + CONFIG_BOOLEAN});		
		AddSetting({name = "speed_town_to_city", description = "Maximum road speed for town to city connection (km/h)", easy_value = 110, medium_value = 90, hard_value = 70, custom_value = 90, flags = CONFIG_NONE, min_value = 20, max_value = 255, step_size = 5});

		AddSetting({name = "connect_towns_to_towns", description = "----- Connect towns to other towns -----", easy_value = 1, medium_value = 1, hard_value = 0, custom_value = 1, flags = CONFIG_NONE + CONFIG_BOOLEAN});
		AddSetting({name = "max_distance_between_towns_and_towns", description = "Maximum distance between towns", easy_value = 256, medium_value = 128, hard_value = 64, custom_value = 128, flags = CONFIG_NONE, min_value = 20, max_value = 16384});
		AddSetting({name = "restrict_speed_town_to_town", description = "Restrict maximum road speed for town to town connection", easy_value = 1, medium_value = 1, hard_value = 1, custom_value = 1, flags = CONFIG_NONE + CONFIG_BOOLEAN});		
		AddSetting({name = "speed_town_to_town", description = "Maximum road speed for town to town connection (km/h)", easy_value = 90, medium_value = 70, hard_value = 30, custom_value = 70, flags = CONFIG_NONE, min_value = 20, max_value = 255, step_size = 5});
	}
}

RegisterGS(FMainClass());
