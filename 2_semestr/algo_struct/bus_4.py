from collections import defaultdict
import heapq


def fastest_path(routes, start, end):
    route_to_graph = defaultdict(lambda: defaultdict(list))

    for route_idx, route in enumerate(routes):
        for i in range(len(route) - 1):
            route_to_graph[route_idx][route[i]].append(route[i + 1])
            route_to_graph[route_idx][route[i + 1]].append(route[i])

    stop_to_routes = defaultdict(list)
    for route_idx, route in enumerate(routes):
        for stop in route:
            if route_idx not in stop_to_routes[stop]:
                stop_to_routes[stop].append(route_idx)

    # (время, остановка, текущий_маршрут)
    priority_queue = [(0, start, -1)]
    visited = set()

    while priority_queue:
        time, stop, current_route = heapq.heappop(priority_queue)
        if (stop, current_route) in visited:
            continue

        visited.add((stop, current_route))

        if stop == end:
            return time
        # вниз
        for route in stop_to_routes[stop]:
            if route != current_route and (stop, route) not in visited:
                route_switch_time = 3 if current_route != -1 else 0
                heapq.heappush(priority_queue, (time + route_switch_time, stop, route))
        # вправо
        if current_route != -1:
            for next_stop in route_to_graph[current_route][stop]:
                if (next_stop, current_route) not in visited:
                    heapq.heappush(priority_queue, (time + 1, next_stop, current_route))

    return -1


routes = [[1, 2, 3, 4], [3, 5, 6], [2, 5, 7]]
start = 1
end = 7

result = fastest_path(routes, start, end)
print(result)
