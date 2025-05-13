// using System.Collections.Generic;
// using System.Threading;
// using Cysharp.Threading.Tasks;
// using UnityEngine;


// public class TilemapTileTexture : ObjectBase{
//     Vector3Int map_pos => tile.map_pos;
//     // Tilemap TMap;
//     // Transform container => _TMapSys._P3DMon._containers["TileP3D"];
//     // Transform container;
//     LayerType layer;
//     TilemapTile tile;
//     // ---------- GameObject ---------- //
//     // public GameObject _self;
//     public SpriteRenderer _tile_renderer;
//     public PolygonCollider2D _tile_collider;
//     public GameObject _P3D_self;
//     public SpriteRenderer _P3D_renderer;
//     // ---------- Status ---------- //
//     public string tile_ID => tile.tile_ID;
//     public string tile_subID => tile.tile_subID;
    
//     public TilemapTileTexture(TilemapTile tile, GameObject parent, ObjectConfig cfg) : base(parent, cfg){
//         this.tile = tile;
//         layer = new(tile.block.layer, MapLayerType.Middle);
//     }

//     public override void _init_done(){
//         _self.isStatic = true;
//         _tile_renderer = _self.GetComponent<SpriteRenderer>();
//         _tile_collider = _self.GetComponent<PolygonCollider2D>();
//         _tile_collider.enabled = false;
//         _tile_renderer.sortingLayerID = layer.sortingLayerID;
//         _tile_renderer.sortingOrder = layer.sortingOrder;
//         _P3D_self = _self.transform.Find("P3D").gameObject;
//         _P3D_renderer = _P3D_self.GetComponent<SpriteRenderer>();
//         P3D_layer = new(tile.block.layer, MapLayerType.MiddleP3D);
//         _self.transform.position = TilemapAxis._mapping_mapPos_to_worldPos(map_pos, P3D_layer);
//         _renderer.sortingLayerID = P3D_layer.sortingLayerID;
//         _renderer.sortingOrder = P3D_layer.sortingOrder;
//     }


//     public async UniTask _update_texture(){
//         await _wait_init_done();
//         if (tile_subID == null) return;
//         _update_sprite();
//     }

//     void _update_sprite(){
//         bool need_update_collider = check_collider_need_update();
//         _tile_renderer.sprite = _MatSys._tile._get_sprite(tile_ID, tile_subID);
//         string mat_ID = "TransparentSprite";
//         _tile_renderer.material = _MatSys._mat._get_mat(mat_ID);//TilemapLitMaterial

//         if (need_update_collider){
//             update_collider();
//         }
//     }

//     bool check_collider_need_update(){
//         bool need_update_collider;
//         if (_tile_renderer.sprite != null){
//             string last_subID = _tile_renderer.sprite.name;
//             need_update_collider = last_subID != tile_subID;
//         }
//         else{
//             need_update_collider = true;
//         }
//         return need_update_collider;
//     }

//     void update_collider(){
//         if (tile_ID != GameConfigs._sysCfg.TMap_empty_tile){
//             _tile_collider.enabled = true;
//             _tile_collider.pathCount = _tile_renderer.sprite.GetPhysicsShapeCount();
//             for (int i = 0; i < _tile_collider.pathCount; i++){
//                 List<Vector2> path = new List<Vector2>();
//                 _tile_renderer.sprite.GetPhysicsShape(i, path);
//                 _tile_collider.SetPath(i, path.ToArray());
//             }
//         }
//         else{
//             _tile_collider.enabled = false;
//         }

//     }
// }
