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

import("util.superlib", "SuperLib", 40);
RoadBuilder <- SuperLib.RoadBuilder;

class MagicRoadBuilder {
    // Setting for cities to cities and towns to towns
    max_connected_towns = null;

    // Settings cities to cities
    connect_cities_to_cities = null;
    max_distance_between_cities = null;
    speed_city_to_city = null;

    // Settings towns to cities
    connect_towns_to_cities = null;
    max_distance_between_towns_and_cities = null;
    speed_town_to_city = null;

    // Settings towns to towns
    connect_towns_to_towns = null;
    max_distance_between_towns_and_towns = null;
    speed_town_to_town = null;

    // Already connected towns
    connected_towns = null;
    unconnectable_towns = null;

    // Job finished
    job_finished = null;

    iteration_distance = 0;

    constructor() {
        this.max_connected_towns = GSController.GetSetting("max_connected_towns");

        this.connect_cities_to_cities = GSController.GetSetting("connect_cities_to_cities");
        this.max_distance_between_cities = GSController.GetSetting("max_distance_between_cities");
        this.speed_city_to_city = GSController.GetSetting("speed_city_to_city");

        this.connect_towns_to_cities = GSController.GetSetting("connect_towns_to_cities");
        this.max_distance_between_towns_and_cities = GSController.GetSetting("max_distance_between_towns_and_cities");
        this.speed_town_to_city = GSController.GetSetting("speed_town_to_city");

        this.connect_towns_to_towns = GSController.GetSetting("connect_towns_to_towns");
        this.max_distance_between_towns_and_towns = GSController.GetSetting("max_distance_between_towns_and_towns");
        this.speed_town_to_town = GSController.GetSetting("speed_town_to_town");

        this.connected_towns = array(0);
        this.unconnectable_towns = array(0);

        this.job_finished = false;
    }
}

enum ConnectionMode {
    MODE_CITIES_TO_CITIES,
    MODE_TOWNS_TO_CITIES,
    MODE_TOWNS_TO_TOWNS,
}

function MagicRoadBuilder::GetConnectionModeName(mode) {
    switch (mode)     {
        case ConnectionMode.MODE_CITIES_TO_CITIES:
            return "cities to cities";
        case ConnectionMode.MODE_TOWNS_TO_CITIES:
            return "towns to cities";
        case ConnectionMode.MODE_TOWNS_TO_TOWNS:
            return "towns to neighbor";
        default:
            return "Unknown";
    }
}

function MagicRoadBuilder::StoreConnection(source, destination) {
    this.connected_towns.push({source = source, destination = destination});
}

function MagicRoadBuilder::StoreUnconnectable(source, destination) {
    this.unconnectable_towns.push({source = source, destination = destination});
}

function MagicRoadBuilder::TownsAlreadyConnected(source, destination) {
    if (this.connected_towns.len() > 0) {
        foreach(idx,val in this.connected_towns) {
            if (val.source == source && val.destination == destination || val.source == destination && val.destination == source) {
               return true;
            }
        }
    }
    return false;
}

function MagicRoadBuilder::TownsCantConnect(source, destination) {
    if (this.unconnectable_towns.len() > 0) {
        foreach(idx,val in this.unconnectable_towns) {
            // For unconnectable, we test only a->b direction, as the opposite direction might be connectable (existing single way road by exemple)
            if (val.source == source && val.destination == destination) {
               return true;
            }
        }
    }
    return false;
}

function MagicRoadBuilder::BuildRoads() {
    if (this.connected_towns != null && this.connected_towns.len() > 0) {
        GSLog.Info("Already connected towns:");
        foreach(idx,val in this.connected_towns) {
            GSLog.Info(GSTown.GetName(val.source) + " <-> " + GSTown.GetName(val.destination));
        }
    }

    // We clear the unconnectable_towns array as the players may have done some changes that make the connection now possible!
    this.unconnectable_towns = array(0);

    local max_distance_setting = max(max(max_distance_between_cities, max_distance_between_towns_and_cities), max_distance_between_towns_and_towns);

    while (this.iteration_distance < max_distance_setting) {
        // Each iteration we look for town farther
        this.iteration_distance += 50;

        GSLog.Info("Iterate towns in a range of " + min(this.iteration_distance, max_distance_setting) + " tiles");

        /// Find cities
        local cities = GSTownList();
        cities.Valuate(function(id) { if (GSTown.IsCity(id)) return 1; return 0; } );
        cities.KeepValue(1);
        
        /// Find towns
        local towns = GSTownList();
        towns.Valuate(function(id) { if (GSTown.IsCity(id)) return 1; return 0; } );
        towns.KeepValue(0);

        // Prepare working lists
        local sources = GSList();
        local destinations = GSList();

        // Connect cities together whatever the distance they are
        if (connect_cities_to_cities) {
            sources.Clear();
            sources.AddList(cities);
            destinations.Clear();
            destinations.AddList(cities);
            this.ConnectTowns(sources, destinations, ConnectionMode.MODE_CITIES_TO_CITIES);
        }

        // Connect towns to nearest city whatever the distance it is
        if (connect_towns_to_cities) {
            sources.Clear();
            sources.AddList(towns);
            destinations.Clear();
            destinations.AddList(cities);
            this.ConnectTowns(sources, destinations, ConnectionMode.MODE_TOWNS_TO_CITIES);
        }

        // Connect towns to nearest towns
        if (connect_towns_to_towns) {
            sources.Clear();
            sources.AddList(towns);
            destinations.Clear();
            destinations.AddList(towns);
            this.ConnectTowns(sources, destinations, ConnectionMode.MODE_TOWNS_TO_TOWNS);
        }
    }

    // After this loop iteration, we will be done, or a new town has be founded (actually, may not happend 
    job_finished = true;
    
    // We re-enable distance optimisation for next iteration
    this.iteration_distance = 0;
}

function MagicRoadBuilder::ConnectTowns(sources, destinations, mode) {
    local max_distance;
    local max_destinations;
    local reuse_existing_road;
    local destinations_original = null;

    destinations_original = GSList();
    destinations_original.AddList(destinations);

    GSRoad.SetCurrentRoadType(this.ChooseRoadType(mode));
    GSLog.Info("Connecting " + this.GetConnectionModeName(mode));

    switch (mode) {
        case ConnectionMode.MODE_CITIES_TO_CITIES:
            max_distance = min(this.iteration_distance, max_distance_between_cities);
            max_destinations = max_connected_towns;
            reuse_existing_road = false;
            break;
        case ConnectionMode.MODE_TOWNS_TO_CITIES:
            max_distance = min(this.iteration_distance, max_distance_between_towns_and_cities);
            reuse_existing_road = true;
            max_destinations = 1;
            break;
        case ConnectionMode.MODE_TOWNS_TO_TOWNS:
            max_distance = min(this.iteration_distance, max_distance_between_towns_and_towns);
            reuse_existing_road = true;
            max_destinations = max_connected_towns;
            break;
        default:
            GSLog.Error("Invalid mode: " + mode);
            return;
    }

    foreach (source,val in sources) {
        GSLog.Info(GSTown.GetName(source));
        
        // We need the complete list of destinations (even for cities to cities as the a->b path finder may have failed)
        destinations = GSList();
        destinations.AddList(destinations_original);

        // Remove the source town from destinations
        destinations.RemoveItem(source);

        // Choose which destinations to keep
        destinations.Valuate(function(me, other) { return GSMap.DistanceManhattan(GSTown.GetLocation(me), other); }, GSTown.GetLocation(source));

        // Keep only towns that are close enougth
        destinations.RemoveAboveValue(max_distance);

        if (destinations.Count() == 0) {
            GSLog.Info(" -> No destination to connect");
            continue;
        }

        destinations.Sort(GSList.SORT_BY_VALUE, GSList.SORT_ASCENDING);
        local remain_destination = max_destinations;

        foreach (destination,val in destinations) {
            if (this.TownsAlreadyConnected(source, destination) || this.TownsCantConnect(source, destination)) {
                remain_destination--;
            } else if (this.BuildRoad(source, destination, destinations.GetValue(destination), reuse_existing_road)) {
                GSLog.Info("  -> " + GSTown.GetName(destination) + " : done");
                this.StoreConnection(source, destination);
                remain_destination--;
            } else {
                GSLog.Info("  -> " + GSTown.GetName(destination) + " : can't be reached");
                this.StoreUnconnectable(source, destination);
            }

            if (remain_destination == 0) {
                break;
            }
        }
    }
}

function MagicRoadBuilder::BuildRoad(source, destination, distance, repair_existing) {
    local res = null;

    local roadBuilder = RoadBuilder();
    roadBuilder.Init(GSTown.GetLocation(destination), GSTown.GetLocation(source), repair_existing, 1000000);

    res = roadBuilder.DoPathfinding();
    if (res) {
        switch (roadBuilder.ConnectTiles())
        {
            case RoadBuilder.CONNECT_SUCCEEDED:
                break;
            case RoadBuilder.CONNECT_FAILED_OTHER:
                GSLog.Warning("Failed to build road on found path!");
                res = false;
                break;
            case RoadBuilder.CONNECT_FAILED_TIME_OUT:
                GSLog.Warning("Build connection was to slow and was aborted!");
                res = false;
                break;
            case RoadBuilder.CONNECT_FAILED_NO_PATH_FOUND:
                GSLog.Warning("Build connection didn't find valid path: did someone blocked me?");
                res = false;
                break;
            case RoadBuilder.CONNECT_FAILED_OUT_OF_TRIES:
                GSLog.Warning("Build connection tried many time but gave up!");
                res = false;
                break;
        }
    }

    return res;
}

function MagicRoadBuilder::ChooseRoadType(mode) {
    const game_speed_to_kmph_factor = 2.01168;

    local ret = null;
    local company_zero = GSCompanyMode(0);
    local roadTypeList = GSRoadTypeList(GSRoad.ROADTRAMTYPES_ROAD);
    local max_speed = 0;

    roadTypeList.Valuate(function(roadType) { return GSRoad.IsRoadTypeAvailable(roadType) ? 1 : 0; });
    roadTypeList.KeepValue(1);
    company_zero = null;
    roadTypeList.Valuate(GSRoad.GetMaxSpeed);
    roadTypeList.Sort(GSList.SORT_BY_VALUE, GSList.SORT_DESCENDING);
    
    // Save list
    local tmp_roadTypeList = GSList();
    roadTypeList.AddList(tmp_roadTypeList);

    GSLog.Info("Finding best road type for connecting " + this.GetConnectionModeName(mode));

    switch (mode) {
        case ConnectionMode.MODE_CITIES_TO_CITIES:
            max_speed = speed_city_to_city;
            break;
        case ConnectionMode.MODE_TOWNS_TO_CITIES:
            max_speed = speed_town_to_city;
            break;
        case ConnectionMode.MODE_TOWNS_TO_TOWNS:
            max_speed = speed_town_to_town;
            break;
    }

    // Some NewGRF are based on MPH so there can be some cast error : 110 km/h may will be 112 in the NewGRF then we add 2%
    max_speed *= 1.02;

    // Conversion km/h to game internal speed
    max_speed *= game_speed_to_kmph_factor;

    // We keep only road with lower speed (included)
    roadTypeList.RemoveAboveValue(ceil(max_speed).tointeger());

    // There is no road type as fast as max speed, we get back all the roads types
    if (roadTypeList.Count() < 1) {
        roadTypeList.AddList(tmp_roadTypeList);
    }

    // We get the faster road from the list
    ret = roadTypeList.Begin();

    GSLog.Info("Chosen roadType: " + GSRoad.GetName(ret) + " with speed of " + ceil(GSRoad.GetMaxSpeed(ret) / game_speed_to_kmph_factor) + " km/h");
    return ret;
}

MagicRoadBuilder <- MagicRoadBuilder();