import("util.superlib", "SuperLib", 40);
RoadPathFinder <- SuperLib.RoadPathFinder;

class RoadBuilder
{
    max_distance_between_towns = null;
    max_connected_towns = null;

    MODE_CITIES_TO_CITIES = 0;
    MODE_TOWNS_TO_CITIES = 1;
    MODE_TOWNS_TO_NEIGHBOR = 2;
}

function RoadBuilder::constructor()
{
	this.max_distance_between_towns = GSController.GetSetting("max_distance_between_towns");
	this.max_connected_towns = GSController.GetSetting("max_connected_towns");
}

function RoadBuilder::BuildRoads()
{
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
    ConnectTowns(sources, destinations, MODE_CITIES_TO_CITIES);

    // Connect towns to nearest city whatever the distance it is
    sources.Clear();
    sources.AddList(towns);
    destinations.Clear();
    destinations.AddList(cities);
    ConnectTowns(sources, destinations, MODE_TOWNS_TO_CITIES);

    // Connect towns to 4 nearest towns
    sources.Clear();
    sources.AddList(towns);
    destinations.Clear();
    destinations.AddList(towns);
    ConnectTowns(sources, destinations, MODE_TOWNS_TO_NEIGHBOR);
}

function ConnectTowns(sources, destinations, mode)
{
    local max_distance;
    local max_destinations;
    local reuse_existing_road;

    switch (mode)
    {
        case MODE_CITIES_TO_CITIES:
            GSLog.Info("Connecting cities to cities");
            max_distance = GSMap.GetMapSizeX() + GSMap.GetMapSizeY();
            max_destinations = destinations.Count() - 1;
            reuse_existing_road = false;
            break;
        case MODE_TOWNS_TO_CITIES:
            GSLog.Info("Connecting towns to nearest city");
            max_distance = GSMap.GetMapSizeX() + GSMap.GetMapSizeY();
            reuse_existing_road = true;
            max_destinations = 1;
            break;
        case MODE_TOWNS_TO_NEIGHBOR:
            GSLog.Info("Connecting towns to neighbor");
            max_distance = max_distance_between_towns;
            reuse_existing_road = true;
            max_destinations = max_connected_towns;
            break;
        default:
            GSLog.Error("Invalid mode: " + mode);
            return;
    }

    foreach (source,val in sources)
    {
        GSLog.Info(GSTown.GetName(source));
        
        // Remove the source town from destinations
        local dests = GSList();
        dests.AddList(destinations);
        dests.RemoveItem(source);

        // Choose which destinations to keep
        dests.Valuate(function(me, other) { return GSMap.DistanceManhattan(GSTown.GetLocation(me), other); }, GSTown.GetLocation(source));

        // Keep only towns that are close enougth
        dests.KeepBelowValue(max_distance);
        dests.Sort(GSList.SORT_BY_VALUE, GSList.SORT_ASCENDING);
        dests.KeepTop(max_destinations);

        foreach (destination,val in dests)
        {
            GSLog.Info("  -> " + GSTown.GetName(destination));
            this.BuildRoad(source, destination, dests.GetValue(destination), reuse_existing_road);
        }
    }
}

function RoadBuilder::BuildRoad(source, destination, distance, repair_existing)
{
	GSRoad.SetCurrentRoadType(GSRoad.ROADTYPE_ROAD);

    local PathFinder = RoadPathFinder(false);
	PathFinder.InitializePath([GSTown.GetLocation(source)], [GSTown.GetLocation(destination)], repair_existing);
	
	local path = false;
	while (path == false) {
		path = PathFinder.FindPath(10000000);
		GSController.Sleep(1);
	}
	if (path == null) {
		GSLog.Error("pathfinder.FindPath return NULL");
        switch (PathFinder.GetFindPathError())
        {
            case PathFinder.PATH_FIND_NO_ERROR:
                GSLog.Error("no error... wtf!?");
                break;
            case PathFinder.PATH_FIND_FAILED_NO_PATH:
                GSLog.Error("There is definitely no path");
                break;
            case PathFinder.PATH_FIND_FAILED_TIME_OUT:
                GSLog.Error("why the hell did it timed out?");
                break;
            default:
                GSLog.Error("unknow error value: " + PathFinder.GetFindPathError());
                break;
        }
	}
    else
    {
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
}

RoadBuilder <- RoadBuilder();