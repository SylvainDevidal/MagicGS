import("util.superlib", "SuperLib", 40);
RoadPathFinder <- SuperLib.RoadPathFinder;

class RoadBuilder {
    // Instance variables
    max_distance_between_towns = null;
    max_connected_towns = null;
    connected_towns = null;

    constructor()     {
        this.max_distance_between_towns = GSController.GetSetting("max_distance_between_towns");
        this.max_connected_towns = GSController.GetSetting("max_connected_towns");
        this.connected_towns = array(0);
    }
}

enum ConnectionMode {
    MODE_CITIES_TO_CITIES,
    MODE_TOWNS_TO_CITIES,
    MODE_TOWNS_TO_NEIGHBOR,
}

function RoadBuilder::GetConnectionModeName(mode) {
    switch (mode)     {
        case ConnectionMode.MODE_CITIES_TO_CITIES:
            return "cities to cities";
        case ConnectionMode.MODE_TOWNS_TO_CITIES:
            return "towns to cities";
        case ConnectionMode.MODE_TOWNS_TO_NEIGHBOR:
            return "towns to neighbor";
        default:
            return "Unknown";
    }
}

function RoadBuilder::StoreConnection(source, destination) {
    this.connected_towns.push({source = source, destination = destination});
}

function RoadBuilder::TownsAlreadyConnected(source, destination) {
    if (this.connected_towns.len() > 0) {
        foreach(idx,val in this.connected_towns) {
            if (val.source == source && val.destination == destination || val.source == destination && val.destination == source) {
               return true;
            }
        }
    }
    return false;
}

function RoadBuilder::BuildRoads() {
    if (this.connected_towns != null && this.connected_towns.len() > 0) {
        GSLog.Info("Already connected towns:");
        foreach(idx,val in this.connected_towns) {
            GSLog.Info(GSTown.GetName(val.source) + " <-> " + GSTown.GetName(val.destination));
        }
    }

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
    sources.Clear();
    sources.AddList(cities);
    destinations.Clear();
    destinations.AddList(cities);
    ConnectTowns(sources, destinations, ConnectionMode.MODE_CITIES_TO_CITIES);

    // Connect towns to nearest city whatever the distance it is
    sources.Clear();
    sources.AddList(towns);
    destinations.Clear();
    destinations.AddList(cities);
    ConnectTowns(sources, destinations, ConnectionMode.MODE_TOWNS_TO_CITIES);

    // Connect towns to 4 nearest towns
    sources.Clear();
    sources.AddList(towns);
    destinations.Clear();
    destinations.AddList(towns);
    ConnectTowns(sources, destinations, ConnectionMode.MODE_TOWNS_TO_NEIGHBOR);
}

function ConnectTowns(sources, destinations, mode)
{
    local max_distance;
    local max_destinations;
    local reuse_existing_road;
    local destinations_original = null;

    GSRoad.SetCurrentRoadType(ChooseRoadType(mode));
    GSLog.Info("Connecting " + GetConnectionModeName(mode));

    switch (mode) {
        case ConnectionMode.MODE_CITIES_TO_CITIES:
            max_distance = GSMap.GetMapSizeX() + GSMap.GetMapSizeY();
            max_destinations = destinations.Count() - 1;
            reuse_existing_road = false;
            break;
        case ConnectionMode.MODE_TOWNS_TO_CITIES:
            max_distance = GSMap.GetMapSizeX() + GSMap.GetMapSizeY();
            reuse_existing_road = true;
            max_destinations = 1;
            destinations_original = GSList();
            destinations_original.AddList(destinations);
            break;
        case ConnectionMode.MODE_TOWNS_TO_NEIGHBOR:
            max_distance = max_distance_between_towns;
            reuse_existing_road = true;
            max_destinations = max_connected_towns;
            destinations_original = GSList();
            destinations_original.AddList(destinations);
            break;
        default:
            GSLog.Error("Invalid mode: " + mode);
            return;
    }

    foreach (source,val in sources) {
        GSLog.Info(GSTown.GetName(source));
        
        if (destinations_original != null) {
            // We need the complete list of destinations
            destinations = GSList();
            destinations.AddList(destinations_original);
        }

        // Remove the source town from destinations
        destinations.RemoveItem(source);

        // Choose which destinations to keep
        destinations.Valuate(function(me, other) { return GSMap.DistanceManhattan(GSTown.GetLocation(me), other); }, GSTown.GetLocation(source));

        // Keep only towns that are close enougth
        destinations.KeepBelowValue(max_distance);
        destinations.Sort(GSList.SORT_BY_VALUE, GSList.SORT_ASCENDING);
        local remain_destination = max_destinations;

        foreach (destination,val in destinations) {
            GSLog.Info("  -> " + GSTown.GetName(destination));
            if (TownsAlreadyConnected(source, destination)) {
                remain_destination--;
            } else if (this.BuildRoad(source, destination, destinations.GetValue(destination), reuse_existing_road)) {
                this.StoreConnection(source, destination);
                remain_destination--;
            }

            if (remain_destination <= 0) {
                break;
            }
        }
    }
}

function RoadBuilder::BuildRoad(source, destination, distance, repair_existing)
{
    local res = true;

    local PathFinder = RoadPathFinder(false);
	PathFinder.InitializePath([GSTown.GetLocation(destination)], [GSTown.GetLocation(source)], repair_existing);
	
	local path = null;
	local pf_error = PathFinder.PATH_FIND_NO_ERROR;
	PathFinder.SetMaxIterations(10000000);
	while (path == null && pf_error == PathFinder.PATH_FIND_NO_ERROR) {
		path = PathFinder.FindPath(100);
		pf_error = PathFinder.GetFindPathError();
	}

	if (path == null) {
        res = false;
        switch (pf_error) {
            case PathFinder.PATH_FIND_NO_ERROR:
                GSLog.Error("No path and... no error. WTF!?");
                break;
            case PathFinder.PATH_FIND_FAILED_NO_PATH:
                GSLog.Warning("There is definitely no path.");
                break;
            case PathFinder.PATH_FIND_FAILED_TIME_OUT:
                GSLog.Error("why the hell did it timed out?");
                break;
            default:
                GSLog.Error("Unknown error value: " + pf_error);
                break;
        }
    } else {
        while (path != null) {
            local par = path.GetParent();
            if (par != null) {
                local last_node = path.GetTile();
                if (GSMap.DistanceManhattan(path.GetTile(), par.GetTile()) == 1) {
                    if (!GSRoad.BuildRoad(path.GetTile(), par.GetTile())) {
                        /* An error occured while building a piece of road. TODO: handle it.
                        * Note that this can also be the case of the road was already build */
                    }
                } else {
                    if (!GSBridge.IsBridgeTile(path.GetTile()) && !GSTunnel.IsTunnelTile(path.GetTile())) {
                        if (GSRoad.IsRoadTile(path.GetTile())) GSTile.DemolishTile(path.GetTile());
                        if (GSTunnel.GetOtherTunnelEnd(path.GetTile()) == par.GetTile()) {
                            if (!GSTunnel.BuildTunnel(GSVehicle.VT_ROAD, path.GetTile())) {
                                GSLog.Warning("Error building tunnel");
                            }
                        } else {
                            local bridge_list = GSBridgeList_Length(GSMap.DistanceManhattan(path.GetTile(), par.GetTile()) + 1);
                            bridge_list.Valuate(GSBridge.GetPrice, GSMap.DistanceManhattan(path.GetTile(), par.GetTile()));
                            bridge_list.Sort(GSList.SORT_BY_VALUE, GSList.SORT_ASCENDING);
                            if (!GSBridge.BuildBridge(GSVehicle.VT_ROAD, bridge_list.Begin(), path.GetTile(), par.GetTile())) {
                                GSLog.Warning("Error building bridge");
                            }
                        }
                    }
                }
            }
            path = par;
        }
    }
    return res;
}

function RoadBuilder::ChooseRoadType(mode) {
    local ret = GSRoad.ROADTYPE_ROAD; // Set default road type
    local speed = (mode == ConnectionMode.MODE_CITIES_TO_CITIES) ? 0 : 1000;
    local town_to_city_road_speed = 90 * 2.01168;

    local company_zero = GSCompanyMode(0);
    local roadTypeList = GSRoadTypeList(GSRoad.ROADTRAMTYPES_ROAD);
    roadTypeList.Valuate(function(roadType) { return GSRoad.IsRoadTypeAvailable(roadType) ? 1 : 0; });
    roadTypeList.KeepValue(1);
    company_zero = null;
    roadTypeList.Valuate(GSRoad.GetMaxSpeed);

    GSLog.Info("Finding best road type for connecting " + GetConnectionModeName(mode));
    foreach (roadtype,val in roadTypeList) {
        switch (mode) {
            case ConnectionMode.MODE_CITIES_TO_CITIES: // Max speed
                if (val > speed) {
                    speed = val
                    ret = roadtype;
                }
                break;
            case ConnectionMode.MODE_TOWNS_TO_CITIES: // Min speed higher than 60mph
                if (val >= town_to_city_road_speed && val < speed) {
                    speed = val
                    ret = roadtype;
                }
                break;
            case ConnectionMode.MODE_TOWNS_TO_NEIGHBOR: // Min speed possible
                if (val < speed) {
                    speed = val
                    ret = roadtype;
                }
                break;
        }
    }
    GSLog.Info("Chosen roadType: " + GSRoad.GetName(ret) + " with speed of " + speed / 2.01168 + " km/h");
    return ret;
}

RoadBuilder <- RoadBuilder();