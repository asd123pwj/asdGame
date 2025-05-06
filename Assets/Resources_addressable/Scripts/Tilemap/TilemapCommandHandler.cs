using System.Collections.Generic;
using System.Threading;
using Cysharp.Threading.Tasks;
using UnityEngine;

public class TilemapCommandHandler: CommandHandlerBase{
    public override void register(){
        CommandSystem._add(TMapGen);
        CommandSystem._add(TMapDrawTile);
        CommandSystem._add(TMapSetSelectedTile);
    }

    public async UniTask TMapGen(Dictionary<string, object> args, CancellationToken? ct){
        /* TMapGen                    
         * --[useMousePos] (flag)         world_pos
         * --[x_block] (int)            block_pos.x
         * --[y_block] (int)            block_pos.y
         * --[layer] (string)         tile.block.layer
         * --[sortingOrder] (int)     tile.block.layer.sortingOrder
         * --[prepareOnly] (flag)       prepare, no draw
         * 
         * Example:
         *   TMapGen --useMousePos
         *   TMapGen --x_block 0 --y_block 0
         */
        LayerType layer_type;
        Vector3Int block_offsets;

        if (args.TryGetValue("layer", out object layer)){
            layer_type = new((string)layer);
        }
        else if (args.TryGetValue("sortingOrder", out object sortingOrder)){
            layer_type = new((int)sortingOrder);
        }
        else{
            layer_type = _CtrlSys._get_current_layer();
            // Debug.Log($"No layer or sortingOrder specified, using current layer {layer_type}");
        }

        if(args.ContainsKey("useMousePos")){
            Vector2 mousePos = InputSystem._keyPos.mouse_pos_world;
            block_offsets = TilemapAxis._mapping_worldPos_to_blockOffsets(mousePos, layer_type);
        }
        else{
            block_offsets = new Vector3Int((int)args["x_block"], (int)args["y_block"], 0);
        }

        if (args.ContainsKey("prepareOnly")){
            await _TMapSys._TMapCtrl._prepare_block(block_offsets, layer_type, ct);
        }
        else{
            await _TMapSys._TMapCtrl._draw_block_complete(block_offsets, layer_type, ct);
        }
        
    }

    public async UniTask TMapDrawTile(Dictionary<string, object> args, CancellationToken? ct){
        /* TMapDrawTile                    
         * --[useMousePos] (flag)     
         * --[x_map] (int)            tile.map_pos.x
         * --[y_map] (int)            tile.map_pos.y
         * --[layer] (string)         tile.block.layer,              if not specified, use _CtrlSys._get_current_layer();
         * --[sortingOrder] (int)     tile.block.layer.sortingOrder, if not specified, use _CtrlSys._get_current_layer();
         * --[tile_ID] (string)       tile.tile_ID,                  if not specified, use selected tile in _TMapSys.TMapMon._tile_ID_selected4Draw
         * --[needDraw] (flag)        modify and draw
         * 
         * Example:
         *   TMapDrawTile --useMousePos --tile_ID b6 --needDraw
         *   - In mousePos, player current layer, modify tile to "b6", and draw
         *   TMapDrawTile --x_map 0 --x_map 0, --layer L0_Middle
         *   - In (0, 0), L0 of L0_Middle, modify tile to _TMapSys.TMapMon._tile_ID_selected4Draw, and draw
         */
        LayerType layer_type;
        Vector3Int map_pos;

        if (args.TryGetValue("layer", out object layer)){
            layer_type = new((string)layer);
        }
        else if (args.TryGetValue("sortingOrder", out object sortingOrder)){
            layer_type = new((int)sortingOrder);
        }
        else{
            layer_type = _CtrlSys._get_current_layer();
        }

        if(args.ContainsKey("useMousePos")){
            Vector2 mousePos = InputSystem._keyPos.mouse_pos_world;
            map_pos = TilemapAxis._mapping_worldPos_to_mapPos(mousePos, layer_type);
        }
        else{
            map_pos = new Vector3Int((int)args["x_map"], (int)args["y_map"], 0);
        }

        if (!args.TryGetValue("tile_ID", out object tile_ID)){
            tile_ID = _TMapSys._TMapMon._tile_ID_selected4Draw;
        }

        bool needDraw = args.ContainsKey("needDraw");

        await TilemapTile._modify(layer_type, map_pos, (string)tile_ID, ct, needDraw);
    }

    public async UniTask TMapSetSelectedTile(Dictionary<string, object> args, CancellationToken? ct){
        await Placeholder.noAsyncWarning();
        /* TMapDrawTile                    
         * --[tile_ID] (string)       if not specified, use GameConfig._sysCfg.TMap_empty_tile
         * 
         * Example:
         *   TMapSetSelectedTile --tile_ID b6
         *   - Set selected tile to "b6"
         *   TMapSetSelectedTile
         *   - Set selected tile to GameConfig._sysCfg.TMap_empty_tile
         */
        // LayerType layer_type = new();
        if (!args.TryGetValue("tile_ID", out object tile_ID)){
            tile_ID = GameConfigs._sysCfg.TMap_empty_tile;
        }
        Debug.Log($"Set selected tile to {tile_ID}");
        _TMapSys._TMapMon._tile_ID_selected4Draw = (string)tile_ID;
    }
}