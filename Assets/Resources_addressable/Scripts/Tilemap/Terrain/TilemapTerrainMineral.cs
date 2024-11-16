using System.Collections.Generic;
using System.Linq;
using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;



public class TilemapTerrainMineral: BaseClass{

    public string _get_mineral(Vector3Int map_pos, List<MineralInfo> minerals){
        for (int i = 0; i < minerals.Count; i++){
            Vector3Int offset = Str2Offset._get(minerals[i].ID) * Vector3Int.one;
            if (_GCfg._noise._get_2Ds(map_pos + offset, minerals[i].noise)){
                return minerals[i].ID;
            }
        }
        return null;
    }


}