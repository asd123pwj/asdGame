using System.Collections.Generic;
using Cysharp.Threading.Tasks;
using UnityEngine;

public class TilemapCommandHandler: CommandHandlerBase{
    public override void register(){
        CommandSystem._add(TMapGen);
        CommandSystem._add(TMapMatch);
    }

    public async UniTask TMapGen(Dictionary<string, object> args){
        /* TMapGen                    
         * --useMousePos (flag)         world_pos
         * --[x_block] (int)            block_pos.x
         * --[y_block] (int)            block_pos.y
         * --[prepareOnly] (flag)       prepare, no draw
         * 
         * Example:
         *   TMapGen --useMousePos
         *   TMapGen --x_block 0 --y_block 0
         */
        LayerType layer_type = new();
        Vector3Int block_offsets;
        if(args.ContainsKey("useMousePos")){
            Vector2 mousePos = InputSystem._keyPos.mouse_pos_world;
            block_offsets = TilemapAxis._mapping_worldPos_to_blockOffsets(mousePos, layer_type);
        }
        else{
            block_offsets = new Vector3Int((int)args["x_block"], (int)args["y_block"], 0);
        }
        if (args.ContainsKey("prepareOnly")){
            _TMapSys._TMapCtrl._prepare_block(block_offsets, layer_type).Forget();
        }
        else{
            _TMapSys._TMapCtrl._draw_block_complete(block_offsets, layer_type).Forget();
        }
        
    }

    public async UniTask TMapMatch(Dictionary<string, object> args){
        /* TMapMatch
         * --useMousePos (flag)         world_pos
         * --[x_map] (int)            map_pos.x
         * --[y_map] (int)            map_pos.y
         * 
         * Example:
         *   TMapMatch --useMousePos
         *   TMapMatch --x_map 0 --y_map 0
         */
        LayerType layer_type = new();
        Vector3Int map_pos;
        if(args.ContainsKey("useMousePos")){
            Vector2 mousePos = InputSystem._keyPos.mouse_pos_world;
            map_pos = TilemapAxis._mapping_worldPos_to_mapPos(mousePos, layer_type);
        }
        else{
            map_pos = new Vector3Int((int)args["x_map"], (int)args["y_map"], 0);
        }
        TileMatchRule.match(map_pos, layer_type);
    }

}