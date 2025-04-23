import osmium

class OSMInfo:
    access_keys = ["motorcar", "motor_vehicle", "vehicle", "access"]
    access_values = {"yes", "permissive", "destination", "designated", "customers"}
    highway_values = {
        "motorway": "motorway",
        "trunk": "rural",
        "primary": "rural",
        "secondary": "rural",
        "tertiary": "rural",
        "unclassified": "residential",
        "residential": "residential",
        "living_street": "residential",
        "service": "residential"
    }
    speed_values = {
        "motorway": "70 mph",
        "rural dual carriageway": "65 mph",
        "rural": "55 mph",
        "residential": "30 mph"
    }
    oneway = {"yes", "true", "1"}
    oneway_backward = {"-1", "reverse"}

    restriction_prohibit = {"no_right_turn", "no_left_turn", "no_u_turn", "no_straight_on", "no_entry", "no_exit"}
    restriction_require = {"only_right_turn", "only_left_turn", "only_u_turn", "only_straight_on"}

    @staticmethod
    def get_oneway(way):
        if val := way.tags.get("oneway"):
            if val in OSMInfo.oneway: return 1
            if val in OSMInfo.oneway_backward: return -1
        if way.tags.get("junction") == "roundabout": return 1
        return 0

    @staticmethod
    def is_valid_road(way):
        for tag in OSMInfo.access_keys:
            if val := way.tags.get(tag): return val in OSMInfo.access_values
        return way.tags.get("highway") in OSMInfo.highway_values

    @staticmethod
    def find_maxspeed(way):
        if val := way.tags.get("maxspeed"): return val
        highway = way.tags.get("highway")
        if highway not in OSMInfo.highway_values: return "15 mph"  # seems like a sensible default
        if (val := OSMInfo.highway_values[highway]) \
            and val != "rural": return OSMInfo.speed_values[val]
        if OSMInfo.get_oneway(way) and (lanes := way.tags.get("lanes")) \
            and int(lanes) >= 2:
            return OSMInfo.speed_values["rural dual carriageway"]
        return OSMInfo.speed_values["rural"]

    @staticmethod
    def get_maxspeed(way):
        maxspeed = OSMInfo.find_maxspeed(way)
        try: return int(maxspeed.split()[0])
        except: return 15  # safety default

    @staticmethod
    def is_valid_restriction(res):
        val = res.tags.get("restriction")
        if val in OSMInfo.restriction_prohibit: return 2
        if val in OSMInfo.restriction_require: return 3
        return 0
