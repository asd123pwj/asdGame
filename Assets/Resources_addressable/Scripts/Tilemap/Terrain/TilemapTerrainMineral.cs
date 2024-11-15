using System.Collections.Generic;
using System.Linq;
using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;



public class TilemapTerrainMineral: BaseClass{
    // ---------- Horizontal Edge ---------- //
    // public bool _check_mineral(Vector3Int map_pos, Noise2D mineral){
    //     _GCfg._noise._set_fractal_type(mineral.fractal);
    //     _GCfg._noise._set_noise(mineral.noise);
    //     float h_ratio = _GCfg._noise._get(map_pos.x, map_pos.y, mineral.f);
    //     // float h_ratio = _GCfg._noise._perlin_01(map_pos.x, map_pos.y, mineral.f);
    //     // float h_ratio = _GCfg._noise._cellular_2div_01(map_pos.x, map_pos.y, mineral.f);
    //     if (h_ratio < 0 || h_ratio > 1) Debug.Log(h_ratio);
    //     bool allowGenerate = true;
    //     if (mineral.t_min != 0 && h_ratio < mineral.t_min) allowGenerate = false;
    //     if (mineral.t_max != 0 && h_ratio > mineral.t_max) allowGenerate = false;
    //     return allowGenerate;
    // }

    public string _get_mineral(Vector3Int map_pos, List<MineralInfo> minerals){
        for (int i = 0; i < minerals.Count; i++){
            // Vector3Int offset = i * new Vector3Int(100, 100, 0);
            Vector3Int offset = Str2Offset._get(minerals[i].ID) * Vector3Int.one;
            if (_GCfg._noise._get_2Ds(map_pos + offset, minerals[i].noise)){
                return minerals[i].ID;
            }
        }
        return null;
    }


}