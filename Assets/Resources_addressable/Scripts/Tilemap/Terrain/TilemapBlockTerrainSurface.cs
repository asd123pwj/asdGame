using System.Linq;
using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;


public class TilemapBlockTerrainSurface: BaseClass{
    public bool _check_underground(Vector3Int map_pos, TerrainHier1 hier1){
        // int surface_h = _GCfg._noise._get_heights(new(map_pos.x, 0), hier1.surface);
        int surface_h = GameConfigs._noise._get_int(map_pos, hier1.surface);
        if (map_pos.y > surface_h) return false;
        else return true;
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