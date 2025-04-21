using System.Collections.Generic;
using UnityEngine;

public class TilemapCommandHandler: CommandHandlerBase{
    public override void register(){
        CommandSystem._add(TMapGen);
    }

    public void TMapGen(Dictionary<string, object> args){
        /* TMapGen                    
         * --useMousePos (flag)         world_pos
         * --[x_block] (int)            block_pos.x
         * --[y_block] (int)            block_pos.y
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
        _TMapSys._TMapCtrl._draw_block_complete(block_offsets, layer_type).Forget();
        
    }

}