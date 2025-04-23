import osmium
from scripts.osm_info import OSMInfo
from shapely.geometry import LineString

def get_node_id(n, osm_to_nodes, nodes):
    if n.ref not in osm_to_nodes:
        osm_to_nodes[n.ref] = len(nodes)
        nodes.append([n.location.x / 1e7, n.location.y / 1e7, {}, {}, []])
    return osm_to_nodes[n.ref]

def add_way(id, o, osm_to_segments, segments, nodes):
    if id not in osm_to_segments: osm_to_segments[id] = []
    seg_id = len(segments)
    osm_to_segments[id].append(seg_id)
    segments.append(o)
    nodes[o[1]][4].append(seg_id)

def process_restriction(o, osm_to_segments, osm_to_nodes):
    invalid = False
    node_id = None
    from_segments = []
    to_segments = []

    for res in o.members:
        if res.type == osmium.osm.RELATION:
            invalid = True
            continue
        elif res.type == osmium.osm.WAY and res.ref in osm_to_segments:
            if res.role == "from": from_segments.append(osm_to_segments[res.ref])
            elif res.role == "to": to_segments.append(osm_to_segments[res.ref])
            else:
                invalid = True
                continue
        elif res.type == osmium.osm.NODE and res.ref in osm_to_nodes:
            if res.role != "via" or node_id is not None:
                invalid = True
                continue
            node_id = osm_to_nodes[res.ref]
        else:
            invalid = True
            continue
    return (invalid, node_id, from_segments, to_segments)

def push_restriction(node_id, from_segments, to_segments, restriction_type, nodes, segments):
    the_from_segment = None
    for from_segment in from_segments:
        if segments[from_segment][2] == node_id:
            the_from_segment = from_segment
            break
    if the_from_segment is None: return

    the_to_segment = None
    for to_segment in to_segments:
        if segments[to_segment][1] == node_id:
            the_to_segment = to_segment
            break
    if the_to_segment is None: return

    node = nodes[node_id]
    if restriction_type == 2:
        if the_from_segment not in node[2]: node[2][the_from_segment] = []
        node[2][the_from_segment].append(the_to_segment)
    elif restriction_type == 3:
        node[3][the_from_segment] = the_to_segment

def parse(INPUT_OSM):
    # [[segment, from, to, distance, pointlike, speed, 0], ...]
    # linestring, internal node id, internal node id, bool, float, int, number of crashes
    segments = []
    # {OSMID: [seg_index, seg_index, ...], ...}
    osm_to_segments = {}

    # [[x, y, {}, {}, []], ...]
    # x, y, prevent restrictions, mandatory restrictions, child way internal ids
    nodes = []
    # {OSMID: node_index, ...}
    osm_to_nodes = {}

    for o in osmium.FileProcessor(INPUT_OSM) \
                    .with_locations() \
                    .with_filter(osmium.filter.EntityFilter(osmium.osm.WAY)) \
                    .with_filter(osmium.filter.KeyFilter("highway")):
        if not OSMInfo.is_valid_road(o): continue
        oneway = OSMInfo.get_oneway(o)
        maxspeed = OSMInfo.get_maxspeed(o)

        i = 0
        while i < len(o.nodes) - 1:
            if not (o.nodes[i].location.valid() and o.nodes[i+1].location.valid()):
                i += 1
                continue
            node_pairs = []
            if oneway != -1: node_pairs.append((o.nodes[i], o.nodes[i+1]))  # not strictly backwards
            if oneway != 1: node_pairs.append((o.nodes[i+1], o.nodes[i]))  # not strictly forwards
            for from_node, to_node in node_pairs:
                line_string = LineString([
                    (from_node.location.x / 1e7, from_node.location.y / 1e7),
                    (to_node.location.x / 1e7, to_node.location.y / 1e7)
                ])
                from_node_id = get_node_id(from_node, osm_to_nodes, nodes)
                to_node_id = get_node_id(to_node, osm_to_nodes, nodes)
                distance = osmium.geom.haversine_distance(
                    from_node.location, to_node.location
                ) / 1609
                point_like = distance < 0.0001
                add_way(
                    o.id,
                    [line_string, from_node_id, to_node_id, distance, point_like, maxspeed, 0],
                    osm_to_segments,
                    segments,
                    nodes
                )
            i += 1

    for o in osmium.FileProcessor(INPUT_OSM) \
                    .with_filter(osmium.filter.EntityFilter(osmium.osm.RELATION)) \
                    .with_filter(osmium.filter.TagFilter(("type", "restriction"))) \
                    .with_filter(osmium.filter.KeyFilter("restriction")):
        restriction_type = OSMInfo.is_valid_restriction(o)
        if restriction_type == 0: continue
        invalid, node_id, from_segments_list, to_segments_list = process_restriction(
            o, osm_to_segments, osm_to_nodes
        )
        if invalid: continue
        for from_segments in from_segments_list:
            for to_segments in to_segments_list:
                push_restriction(
                    node_id, from_segments, to_segments, restriction_type, nodes, segments
                )

    return (nodes, segments)
