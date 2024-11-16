using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;
using YamlDotNet.Core.Events;



public class TilemapTerrainGenerator: BaseClass{
    TilemapTerrainSurface surface;
    TilemapTerrainMineral mineral;

    public TilemapTerrainGenerator(){
        surface = new();
        mineral = new();
    }


    public TilemapBlock _generate_block(Vector3Int block_offsets,
                                        LayerType layer_type){

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
                TerrainHier1 hier1 = surface._get_hier1(map_pos, _MatSys._terrain._infos.HierBase);
                if (surface._check_underground(map_pos, hier1)){
                    // ----- Base Tile ----- //
                    block.map._set_tile(i, j, hier1.base_tile);
                    // ----- Mineral ----- //
                    string mineral_ID = mineral._get_mineral(map_pos, hier1.minerals);
                    if (mineral_ID != null) block.map._get(i, j)._set_mineral(mineral_ID);
                }
                else {
                    block.map._set_tile(i, j, _GCfg._empty_tile);
                }
            }
        }
    }
}