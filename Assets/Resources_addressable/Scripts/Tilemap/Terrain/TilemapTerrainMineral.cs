using System.Collections.Generic;
using System.Linq;
using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;



public class TilemapTerrainMineral: BaseClass{
    // ---------- Horizontal Edge ---------- //
    public bool _check_mineral(Vector3Int map_pos, float frequency, float thres){
        float h_ratio = _GCfg._noise._perlin_01(map_pos.x, map_pos.y, frequency);
        return h_ratio > thres;
    }

    public string _get_mineral(Vector3Int map_pos, List<MineralFrequency> minerals){
        for (int i = 0; i < minerals.Count; i++){
            // Vector3Int offset = i * new Vector3Int(100, 100, 0);
            Vector3Int offset = Str2Offset._get(minerals[i].ID) * Vector3Int.one;
            if (_check_mineral(map_pos + offset, minerals[i].f, minerals[i].t)){
                return minerals[i].ID;
            }
        }
        return null;
    }


}