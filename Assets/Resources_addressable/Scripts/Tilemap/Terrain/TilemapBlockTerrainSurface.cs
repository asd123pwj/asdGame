using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;


public class TilemapBlockTerrainSurface: BaseClass{
    readonly ConcurrentDictionary<int, int> underground_cache = new();

    public bool _check_underground(Vector3Int map_pos, TerrainHier1 hier1){
        if (!underground_cache.TryGetValue(map_pos.x, out int underground_height)){
            underground_height = GameConfigs._noise._get_int(map_pos, hier1.surface);
            underground_cache.TryAdd(map_pos.x, underground_height);
        }
        return map_pos.y <= underground_height;
    }
    
    // ---------- Vertical Edge ---------- //
    // - 我一直不太懂该怎么翻译比较好，这个是地貌边缘，即某个范围内的x共享一个值，这里草原过去了是沙漠这样子
    public float _get_type_value(Vector3Int map_pos, TerrainHierBase hier_base){
        // int x_noise = _GCfg._noise._get_heights(map_pos, hier_base.x_noise);
        // float type_value = _GCfg._noise._get_ratio(new (map_pos.x + x_noise, 0, 0), hier_base.Hier1);
        float type_value = GameConfigs._noise._get_float(map_pos, hier_base.Hier1);

        return type_value;
    }

    public TerrainHier1 _get_hier1(Vector3Int map_pos, TerrainHierBase hier_base){
        float type_value = _get_type_value(map_pos, hier_base);
        int type_ID = RandomGenerator._random_by_prob(_MatSys._terrain._hier1s_prob, type_value);
        TerrainHier1 hier1 = _MatSys._terrain._hier1s[type_ID];
        return hier1;
    }

}