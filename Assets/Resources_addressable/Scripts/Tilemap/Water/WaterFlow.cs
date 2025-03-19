// Ref: https://www.jgallant.com/2d-liquid-simulator-with-cellular-automaton-in-unity/
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class WaterFlow: BaseClass{
    public void _flow_anime(){
        List<string> layers = WaterBase._our.Keys.ToList();
        for (int i = 0; i < layers.Count; i++){
            List<Vector3Int> waters = WaterBase._our[layers[i]].Keys.ToList();
            for (int j = 0; j < waters.Count; j++){
                WaterBase water = WaterBase._our[layers[i]][waters[j]];
                water._amount = water._amount_after;
                if (water._diff != 0 || water._isToppest) water._update_mesh().Forget();
                water._decrease = 0;
                water._increase = 0;
                water._flowed_down = false;
                water._flowed_left = false;
                water._flowed_right = false;
            }
        }     
    }


    public void _flow_logic(){
        List<string> layers = WaterBase._our.Keys.ToList();
        for (int i = 0; i < layers.Count; i++){
            List<Vector3Int> waters = WaterBase._our[layers[i]].Keys.ToList();
            for (int j = 0; j < waters.Count; j++){
                WaterBase water = WaterBase._our[layers[i]][waters[j]];

                // ---------- Step 1: Flow down ---------- //
                if (!check_allow_flow(water)) continue;
                if (check_flow_down(water)){    
                    flow_down(water);       
                    water._flowed_down = true;
                    continue;
                }

                // ---------- Step 2: Flow Right ---------- //
                if (!check_allow_flow(water)) continue;
                // ----- Step 2.1: Flow in one row, e.g. A3 B2 C2 D1 => A2 B2 C2 D2
                Vector3Int pos_dest = water._map_pos;
                int null_count = 0;
                while (!water._flowed_right){           // If: Only flow right once
                    pos_dest += Vector3Int.right;
                    if (water._get_neighbor(pos_dest) == null) null_count++;    
                    if (null_count > 1) break;          // If: Only flow neighbor, neigbhor of neighbor can't flow
                    if (check_flow(water, pos_dest)) {
                        flow(water, pos_dest);
                        water._flowed_right = true;
                    }
                }
                /* ----- Step 2.2: Flow in two row
                 * When amount = 4 = full, for example
                 * - - - 1 -      - - - 0 - 
                 * 3 4 4 4 4   => 4 4 4 4 4
                 */
                if (!water._flowed_right                // If: Only flow right once
                    && water._amount_remain == 1        // If: amount = 1 can flow
                    && water._isToppest                 // If: Toppest can flow down
                    && water._down != null){            // If: Bottomest can't flow down
                    pos_dest = water._down._map_pos;
                    while (!water._flowed_right){
                        pos_dest += Vector3Int.right;
                        if (water._get_neighbor(pos_dest) == null) break;   // If: No space to flow
                        if (check_flow_down(water, pos_dest)) {
                            flow(water, pos_dest);
                            water._flowed_right = true;
                        }
                    }
                }

                // ---------- Step 3: Flow Left ---------- //
                // ----- Step 3.1: Flow in one row, e.g. A1 B2 C2 D3 => A2 B2 C2 D2
                null_count = 0;
                if (!check_allow_flow(water)) continue;
                pos_dest = water._map_pos;
                while (!water._flowed_left){           
                    pos_dest += Vector3Int.left;
                    if (water._get_neighbor(pos_dest) == null) null_count++;
                    if (null_count > 1) break;
                    if (check_flow(water, pos_dest)) {
                        flow(water, pos_dest);
                        water._flowed_left = true;
                    }
                }
                /* ----- Step 3.2: Flow in two row
                 * When amount = 4 = full, for example
                 * - - - 1 -      - - - 0 - 
                 * 4 4 4 4 3   => 4 4 4 4 4
                 */
                if (!water._flowed_left 
                    && water._amount_remain == 1 
                    && water._isToppest
                    && water._down != null){
                    pos_dest = water._down._map_pos;
                    while (!water._flowed_left){
                        pos_dest += Vector3Int.left;
                        if (water._get_neighbor(pos_dest) == null) break;
                        if (check_flow_down(water, pos_dest)) {
                            flow(water, pos_dest);
                            water._flowed_left = true;
                        }
                    }
                }
            }
        }     
    }

    bool check_allow_flow(WaterBase water) => !(water._amount_remain == 0);

    void flow_down(WaterBase water) => flow(water, water._map_pos + Vector3Int.down);
    void flow(WaterBase water, Vector3Int pos_dest){
        // ----- Step 1: Current water amount decrease
        water._decrease += 1;
        // ----- Step 2: Destination water amount increase
        WaterBase water_dest = water._get_neighbor(pos_dest);
        water_dest ??= new WaterBase(pos_dest, water._layer, _sys._TMapSys._TMapMon._transforms["Water"]);
        water_dest._increase += 1;
    }

    bool check_flow_down(WaterBase water) => check_flow_down(water, water._map_pos + Vector3Int.down);
    bool check_flow_down(WaterBase water, Vector3Int pos_dest){
        if (!check_allow_water(water._layer, pos_dest)) return false;  
        WaterBase water_dest = water._get_neighbor(pos_dest);
        if (water_dest != null && water_dest._check_full(isAfter:true)) return false;   // no space to flow
        return true;
    }
    
    bool check_flow(WaterBase water, Vector3Int pos_dest){
        if (!check_allow_water(water._layer, pos_dest)) return false;  
        WaterBase water_dest = water._get_neighbor(pos_dest);
        int dest_amount_after = water_dest == null ? 0 : water_dest._amount_after;
        if (dest_amount_after + 1 >= water._amount_remain) return false;  // why +1? Sample 1: L4 R2 => L3 R3, Sample 2: L4 R3 => L4 R3
        return true;
    }

    bool check_allow_water(LayerType layer, Vector3Int pos_dest){
        // If: Only full tile can't flow, part tile can flow
        if (TilemapTile._check_fullTile(layer, pos_dest)) return false;          
        
        WaterBase water_dest = WaterBase._get_neighbor(layer, pos_dest);
        if (water_dest != null && water_dest._check_full(isAfter:true)) return false;
        return true;
    }

}
