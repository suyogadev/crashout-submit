#include "Graph.hpp"

#include <vector>
#include <string>

#include <nanoflann.hpp>
#include <nlohmann/json.hpp>

struct NodeCloud {
    const std::vector<Node>* nodes;

    inline size_t kdtree_get_point_count() const { return nodes->size(); }

    inline double kdtree_get_pt(const size_t idx, size_t dim) const {
        if (dim == 0) return (*nodes)[idx].x;
        else return (*nodes)[idx].y;
    }

    // not really needed but couldn't hurt to leave it in for stability
    template <class BBOX>
    bool kdtree_get_bbox(BBOX&) const { return false; }
};

using KDTree = nanoflann::KDTreeSingleIndexAdaptor<
    nanoflann::L2_Simple_Adaptor<double, NodeCloud>,
    NodeCloud,
    2
>;

inline double deg2rad(double deg);

inline double haversine(double lat1, double lon1, double lat2, double lon2);

class GraphHelper {
public:
    Graph graph;
    NodeCloud nodeCloud;
    std::unique_ptr<KDTree> kdTree;

    GraphHelper(const std::string& filename);

    nlohmann::json calculatePath(const nlohmann::json& j);

private:
    std::vector<char> read_file(const std::string& filename);

    int find_nearest_node(double x, double y) const;

    std::vector<std::pair<double, double>> getCoords(std::vector<int>& nodeIndices);
};
