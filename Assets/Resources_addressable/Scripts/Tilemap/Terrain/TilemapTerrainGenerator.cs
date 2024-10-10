using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;
using YamlDotNet.Core.Events;



public class TilemapTerrainGenerator: BaseClass{
    // public int surface_top = 1000;
    // public int surface_buttom = -1000;
    TilemapTerrainSurface surface;

    public TilemapTerrainGenerator(){
        surface = new();
    }


    public TilemapBlock _generate_block(Vector3Int block_offsets,
                                        LayerTTT layer_type){

        TilemapBlock block = 
            _TMapSys._TMapMon._check_block_load(block_offsets, layer_type)
            ? _TMapSys._TMapMon._get_block(block_offsets, layer_type)
            : new(block_offsets, layer_type){};
        
        _generate_terrain(block);

        return block;
    }

    public void _generate_terrain(TilemapBlock block){
        for (int i = 0; i < block.size.x; i++){
            for (int j = 0; j < block.size.y; j++){
                Vector3Int map_pos = _TMapSys._TMapAxis._mapping_inBlockPos_to_mapPos(new(i, j), block.offsets);
                TerrainHier1Info hier1 = surface._get_hier1(map_pos);
                if (surface._check_surface(map_pos, hier1) == TerrainType.Overground){
                    block.map._set(i, j, _GCfg._empty_tile);
                }
                else {
                    block.map._set(i, j, hier1.surface);
                }
            }
        }
    }
}