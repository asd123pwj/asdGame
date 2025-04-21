using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;


public enum BlockTypeInZone{
    Fixed,
    UpperLeft,
    LowerRight
}

public enum PrepareStatus{ // even though there are two status, both of them are NO USE
    inQueue,
    Done
}

public class TilemapZoneGenerator: BaseClass{
    Vector3Int zone_size => GameConfigs._sysCfg.TMap_blocks_per_zone;
    Vector3Int connected_size;

    // ---------- Status ---------- // 
    Dictionary<Vector3Int, PrepareStatus> block_prepare_status = new();
    Dictionary<Vector3Int, PrepareStatus> zoneFixed_prepare_status = new();
    Dictionary<Vector3Int, PrepareStatus> zoneUpperLeft_prepare_status = new();
    Dictionary<Vector3Int, PrepareStatus> zoneLowerRight_prepare_status = new();

    public TilemapZoneGenerator(){}
    
    public override void _init(){
        // _sys._InputSys._register_action("Number 3", tmp_draw, "isFirstDown");
        connected_size = new(zone_size.x / 2, zone_size.y / 2);
    }


    // public bool _prepare_block(Vector3Int block_offsets, LayerType layer_type){
    //     if (block_prepare_status.ContainsKey(block_offsets)) return false;
    //     block_prepare_status[block_offsets] = PrepareStatus.inQueue;
        

    //     TilemapBlock block = _TMapSys._TerrGen._generate_block(block_offsets, layer_type);

    //     block_prepare_status[block_offsets] = PrepareStatus.Done;
    //     return true;
    // }



    // public bool tmp_draw(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
    //     Vector3Int block_offsets = TilemapAxis._mapping_worldPos_to_blockOffsets(keyPos.mouse_pos_world, new LayerType());
    //     _prepare_zone_in_blockOffsets(block_offsets);
    //     return true;
    // }




    // public bool _prepare_zone_in_blockOffsets(Vector3Int block_offsets){
    //     if (block_prepare_status.ContainsKey(block_offsets)) return false;
    //     block_prepare_status[block_offsets] = PrepareStatus.inQueue;
        

    //     TilemapBlock block = _TMapSys._TerrGen._generate_block(block_offsets, new LayerType());

    //     // Vector3Int zone_offsets = TilemapAxis._mapping_blockOffsets_to_zoneOffsets(block_offsets);
    //     // BlockTypeInZone block_type = _check_block_type_in_zone(block_offsets);
    //     // // Debug.Log(block_offsets + " - " + zone_offsets + " - " + block_type.ToString());
    //     // switch (block_type){
    //     //     case BlockTypeInZone.Fixed: 
    //     //         _prepare_zone(zone_offsets); 
    //     //         break;
    //     //     case BlockTypeInZone.UpperLeft: 
    //     //         _prepare_zone(zone_offsets); 
    //     //         _prepare_zone(zone_offsets + Vector3Int.up);
    //     //         _prepare_zone(zone_offsets + Vector3Int.left);
    //     //         _prepare_zoneConnected_upperLeft(zone_offsets); 
    //     //         break;
    //     //     case BlockTypeInZone.LowerRight: 
    //     //         _prepare_zone(zone_offsets); 
    //     //         _prepare_zone(zone_offsets + Vector3Int.down);
    //     //         _prepare_zone(zone_offsets + Vector3Int.right); 
    //     //         _prepare_zoneConnected_lowerRight(zone_offsets); 
    //     //         break;
    //     // }

    //     block_prepare_status[block_offsets] = PrepareStatus.Done;
    //     return true;
    // }

    // ---------- Zone ---------- //
    /*   *: The fixed block in zone
     *   /: The connected block between zones
     *  When block * init, all                    block * in the same zone should be init
     *  When block / init, all neighbor connected block / in the same zone should be init, and neighbor zone should be init
     *  ┌------------┬------------┐     
     *  │ /  /  *  * │ /  /  *  * │  
     *  │ /  *  *  * │ /  *  *  * │
     *  │ *  *  *  / │ *  *  *  / │
     *  │ *  *  /  / │ *  *  /  / │
     *  ├------------┼------------┤     
     *  │ /  /  *  * │ /  /  *  * │  
     *  │ /  *  *  * │ /  *  *  * │
     *  │ *  *  *  / │ *  *  *  / │
     *  │ *  *  /  / │ *  *  /  / │
     *  └------------┴------------┘
     *   In _prepare_zone(), the generate order of block is below, i.e., A a B C c1 c2 c3 D d E
     *  ┌------------┐       
     *  │ /  /  D  d │ 
     *  │ /  c2 c3 E │ 
     *  │ B  C  c1 / │ 
     *  │ A  a  /  / │
     *  └------------┘
     *   In _prepare_zoneConnected_lowerRight(), the generate order of block is below, i.e., A a B
     *   In _prepare_zoneConnected_upperLeft(),  the generate order of block is below, i.e., A a B
     *  ┌------------┐       
     *  │ a  A  *  * │  
     *  │ B  *  *  * │ 
     *  │ *  *  *  B │ 
     *  │ *  *  A  a │
     *  └------------┘
     */
    // public BlockTypeInZone _check_block_type_in_zone(Vector3Int block_offsets){
    //     Vector3Int in_zone = TilemapAxis._mapping_blockOffsets_to_blockOffsetsInZone(block_offsets);
    //     // Vector3Int zone_size = _GCfg._sysCfg.TMap_blocks_per_zone;
    //     if (in_zone.x == 0 && in_zone.y >= connected_size.y) return BlockTypeInZone.UpperLeft;
    //     if (in_zone.y == zone_size.y - 1 && in_zone.x < connected_size.x) return BlockTypeInZone.UpperLeft;
    //     if (in_zone.x == zone_size.x - 1 && in_zone.y < connected_size.y) return BlockTypeInZone.LowerRight;
    //     if (in_zone.y == 0 && in_zone.x >= connected_size.x) return BlockTypeInZone.LowerRight;
    //     return BlockTypeInZone.Fixed;
    // }

    // public void _prepare_zone(Vector3Int zone_offsets){
    //     // System.Diagnostics.Stopwatch stopwatch = new();
    //     // stopwatch.Start();
    //     if (zoneFixed_prepare_status.ContainsKey(zone_offsets)) return;
    //     zoneFixed_prepare_status[zone_offsets] = PrepareStatus.inQueue;
        
    //     Vector3Int block_origin = zone_offsets * zone_size;

    //     for (int i = 0; i < connected_size.x; i++){
    //         Vector3Int block_offsets = block_origin + new Vector3Int(i, 0, 0);
    //         // TilemapBlock block = _TMapSys._TMapGen._generate_block(block_offsets, initStage_end:99);
    //         TilemapBlock block = _TMapSys._TerrGen._generate_block(block_offsets, new LayerType());
            
    //         // _TMapSys._TMapDraw._draw_block(block);
    //     }
    //     for (int j = 1; j < connected_size.y; j++){
    //         Vector3Int block_offsets = block_origin + new Vector3Int(0, j, 0);
    //         // TilemapBlock block = _TMapSys._TMapGen._generate_block(block_offsets, initStage_end:99);
    //         TilemapBlock block = _TMapSys._TerrGen._generate_block(block_offsets, new LayerType());
            
    //         // _TMapSys._TMapDraw._draw_block(block);
    //     }
    //     for (int i = 1; i < zone_size.x - 1; i++){
    //         for (int j = 1; j < zone_size.y - 1; j++){
    //             Vector3Int block_offsets = block_origin + new Vector3Int(i, j, 0);
    //             // TilemapBlock block = _TMapSys._TMapGen._generate_block(block_offsets, initStage_end:99);
    //             TilemapBlock block = _TMapSys._TerrGen._generate_block(block_offsets, new LayerType());
            
    //         // _TMapSys._TMapDraw._draw_block(block);
    //         }
    //     }
    //     for (int i = connected_size.x; i < zone_size.x; i++){
    //         Vector3Int block_offsets = block_origin + new Vector3Int(i, zone_size.y - 1, 0);
    //         // TilemapBlock block = _TMapSys._TMapGen._generate_block(block_offsets, initStage_end:99);
    //         TilemapBlock block = _TMapSys._TerrGen._generate_block(block_offsets, new LayerType());
            
    //         // _TMapSys._TMapDraw._draw_block(block);
    //     }
    //     for (int j = zone_size.y - 2; j >= connected_size.y; j--){
    //         Vector3Int block_offsets = block_origin + new Vector3Int(zone_size.x - 1, j, 0);
    //         // TilemapBlock block = _TMapSys._TMapGen._generate_block(block_offsets, initStage_end:99);
    //         TilemapBlock block = _TMapSys._TerrGen._generate_block(block_offsets, new LayerType());
            
    //         // _TMapSys._TMapDraw._draw_block(block);
    //     }

    //     zoneFixed_prepare_status[zone_offsets] = PrepareStatus.Done;
    //     // stopwatch.Stop();
    //     // Debug.Log("Time loop: " + stopwatch.ElapsedMilliseconds);
    // }


    // public void _prepare_zoneConnected_lowerRight(Vector3Int zone_offsets){
    //     if (zoneLowerRight_prepare_status.ContainsKey(zone_offsets)) return;
    //     zoneLowerRight_prepare_status[zone_offsets] = PrepareStatus.inQueue;

    //     Vector3Int block_origin = zone_offsets * zone_size;

    //     for (int i = connected_size.x; i < zone_size.x; i++){
    //         Vector3Int block_offsets = block_origin + new Vector3Int(i, 0, 0);
    //         // TilemapBlock block = _TMapSys._TMapGen._generate_block(block_offsets, initStage_end:99);
    //         TilemapBlock block = _TMapSys._TerrGen._generate_block(block_offsets, new LayerType());
            
    //         // _TMapSys._TMapDraw._draw_block(block);
    //     }
    //     for (int j = 1; j < connected_size.y; j++){
    //         Vector3Int block_offsets = block_origin + new Vector3Int(zone_size.x - 1, j, 0);
    //         // TilemapBlock block = _TMapSys._TMapGen._generate_block(block_offsets, initStage_end:99);
    //         TilemapBlock block = _TMapSys._TerrGen._generate_block(block_offsets, new LayerType());
            
    //         // _TMapSys._TMapDraw._draw_block(block);
    //     }
    //     zoneUpperLeft_prepare_status[zone_offsets] = PrepareStatus.Done;

    // }
    
    // public void _prepare_zoneConnected_upperLeft(Vector3Int zone_offsets){
    //     if (zoneUpperLeft_prepare_status.ContainsKey(zone_offsets)) return;
    //     zoneUpperLeft_prepare_status[zone_offsets] = PrepareStatus.inQueue;

    //     Vector3Int block_origin = zone_offsets * zone_size;

    //     for (int i = connected_size.x - 1; i >= 0; i--){
    //         Vector3Int block_offsets = block_origin + new Vector3Int(i, zone_size.y - 1, 0);
    //         // TilemapBlock block = _TMapSys._TMapGen._generate_block(block_offsets, initStage_end:99);
    //         TilemapBlock block = _TMapSys._TerrGen._generate_block(block_offsets, new LayerType());
            
            
    //         // _TMapSys._TMapDraw._draw_block(block);
    //     }
    //     for (int j = zone_size.y - 2; j >= connected_size.y; j--){
    //         Vector3Int block_offsets = block_origin + new Vector3Int(0, j, 0);
    //         // TilemapBlock block = _TMapSys._TMapGen._generate_block(block_offsets, initStage_end:99);
    //         TilemapBlock block = _TMapSys._TerrGen._generate_block(block_offsets, new LayerType());
            
    //         // _TMapSys._TMapDraw._draw_block(block);
    //     }

    //     zoneLowerRight_prepare_status[zone_offsets] = PrepareStatus.Done;
    // }

}
