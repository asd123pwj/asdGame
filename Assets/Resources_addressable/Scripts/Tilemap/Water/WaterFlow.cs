// Ref: https://www.jgallant.com/2d-liquid-simulator-with-cellular-automaton-in-unity/
using System.Collections.Generic;
using System.Linq;
using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;

public class WaterFlow: BaseClass{
    public void _flow_stage3(){
        List<string> layers = WaterBase._our.Keys.ToList();
        for (int i = 0; i < layers.Count; i++){
            List<Vector3Int> waters = WaterBase._our[layers[i]].Keys.ToList();
            for (int j = 0; j < waters.Count; j++){
                WaterBase water = WaterBase._our[layers[i]][waters[j]];
                if (water._diff != 0) water._update_mesh().Forget();
                water._amount = water._amount_after;
                water._decrease = 0;
                water._increase = 0;
                water._flowed_down = false;
                water._flowed_left = false;
                water._flowed_right = false;
            }
        }     
    }

    public void _flow_stage2(){
        List<string> layers = WaterBase._our.Keys.ToList();
        for (int i = 0; i < layers.Count; i++){
            List<Vector3Int> waters = WaterBase._our[layers[i]].Keys.ToList();
            for (int j = 0; j < waters.Count; j++){
                WaterBase water = WaterBase._our[layers[i]][waters[j]];
                if (!check_allow_flow(water)) continue;
                if (water._flowed_down) continue;       // Water down down down
                // if (water._up != null && water._up._amount_after > 0) continue;
                // Now, water is the toppest water in the column
                // ----- balance row right, // e.g. A3 B2 C2 D1 => A2 B2 C2 D2
                Vector3Int next_pos = water._map_pos;
                while (!water._flowed_right){           
                    next_pos += Vector3Int.right;
                    if (water._get_neighbor(next_pos) == null) break;
                    if (check_flow(water, next_pos)) {
                        flow(water, next_pos);
                        water._flowed_right = true;
                    }
                }
                // ----- balance row left, // e.g. A1 B2 C2 D3 => A2 B2 C2 D2
                next_pos = water._map_pos;
                while (!water._flowed_left){           
                    next_pos += Vector3Int.left;
                    if (water._get_neighbor(next_pos) == null) break;
                    if (check_flow(water, next_pos)) {
                        flow(water, next_pos);
                        water._flowed_left = true;
                    }
                }
            }
        }     
    }

    public void _flow_stage1(){
        List<string> layers = WaterBase._our.Keys.ToList();
        for (int i = 0; i < layers.Count; i++){
            List<Vector3Int> waters = WaterBase._our[layers[i]].Keys.ToList();
            for (int j = 0; j < waters.Count; j++){
                WaterBase water = WaterBase._our[layers[i]][waters[j]];
                // ----- Action 1: Flow down 
                if (!check_allow_flow(water)) continue;
                if (check_flow_down(water)){    
                    flow_down(water);       
                    water._flowed_down = true;
                    continue;
                }
                // ----- Action 2: Flow right, in case of: L4 R2 => L3 R3
                if (!check_allow_flow(water)) continue;
                if (check_flow_right(water)){
                    flow_right(water);      
                    water._flowed_right = true;
                }
                // ----- Action 3: Flow left, in case of: L2 R4 => L3 R3
                if (!check_allow_flow(water)) continue;
                if (check_flow_left(water)){
                    flow_left(water);       // Action 3: Flow left, in case of: L2 R4 => L3 R3
                    water._flowed_left = true;
                }
            }
        }
    }

    bool check_allow_flow(WaterBase water) => !(water._amount_remain == 0);

    void flow_down(WaterBase water) => flow(water, water._map_pos + Vector3Int.down);
    void flow_right(WaterBase water) => flow(water, water._map_pos + Vector3Int.right);
    void flow_left(WaterBase water) => flow(water, water._map_pos + Vector3Int.left);
    void flow(WaterBase water, Vector3Int next_pos){
        // ----- Step 1: Event: Current water amount decrease, _diff -
        water._decrease += 1;
        // ----- Step 2: Event: Next water amount increase, _diff +
        WaterBase water_next = water._get_neighbor(next_pos);
        water_next ??= new WaterBase(next_pos, water._layer, _sys._TMapSys._TMapMon._transforms["Water"]);
        water_next._increase += 1;
    }

    bool check_flow_down(WaterBase water){
        Vector3Int next_pos = water._map_pos + Vector3Int.down;
        if (TilemapTile._check_tile(water._layer, next_pos)) return false;  // have tile, can't fill. But I think it also can fill, cause some tile only part
        WaterBase water_next = water._get_neighbor(next_pos);
        if (water_next != null && water_next._check_full()) return false;   // no space to flow
        return true;
    }
    
    bool check_flow_right(WaterBase water) => check_flow(water, water._map_pos + Vector3Int.right);
    bool check_flow_left(WaterBase water) => check_flow(water, water._map_pos + Vector3Int.left);
    bool check_flow(WaterBase water, Vector3Int next_pos){
        if (TilemapTile._check_tile(water._layer, next_pos)) return false;  // have tile, can't fill. But I think it also can fill, cause some tile only part
        WaterBase water_next = water._get_neighbor(next_pos);
        int next_amount_after = water_next == null ? 0 : water_next._amount_after;
        if (next_amount_after + 1 >= water._amount_remain) return false;  // why +1? Sample1: Left4 Right2 => L3 R3, S2: L4 R3 => L4 R3, S3: L3 R4 => L3 R4
        return true;
    }

}
