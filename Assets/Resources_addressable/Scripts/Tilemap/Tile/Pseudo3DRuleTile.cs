using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;
using System;


[CreateAssetMenu(menuName = "2D/Tiles/Pseudo3D Rule Tile")]
public class Pseudo3DRuleTile : RuleTile<Pseudo3DRuleTile.Neighbor> {
    public static SystemManager _sys;
    public bool isTransparent;
    public bool isPlaceholder;

    public class Neighbor : RuleTile.TilingRule.Neighbor {
        public const int Null = 3;
        public const int NotNull = 4;
    }

    public override bool RuleMatch(int neighbor, TileBase tile) {
        switch (neighbor) {
            case Neighbor.Null: return tile == null;
            case Neighbor.NotNull: return tile != null;
        }
        return base.RuleMatch(neighbor, tile);
    }


    public override void GetTileData(Vector3Int position, ITilemap tilemap, ref TileData tileData){
        base.GetTileData(position, tilemap, ref tileData);
        // var _ = tileData.sprite.name;
        // tile_type = tileType.Other;
        if (tileData.sprite == null) return;
        if (_sys == null) return;
        // Vector2 world_pos = new(position.x, position.y);
        // Transform container = _sys._TMapSys._P3DMon._TMapBD_containers["TileP3D"];
        string tile_ID = _sys._MatSys._tile._get_ID(tileData.sprite);
        string tile_subID = tileData.sprite.name;
        if (tile_ID == null) return;
        if (tile_subID == null) return;

        // new TileP3D(world_pos, container, tile_ID, tile_subID);
        /*
         * TODO: layer type
         */
        string layer = "L1_Middle";

        _sys._TMapSys._P3DMon._update_P3D(position, tile_ID, tile_subID, layer);
        

        // var name = tileData.sprite.name;
        // switch (tileData.sprite.name) { 
        //     case "__Full":    tile_type = tileType.Full; break;
        //     case "__L43":     tile_type = tileType.L43; break;
        //     case "__L32":     tile_type = tileType.L32; break;
        //     case "__L21":     tile_type = tileType.L21; break;
        //     case "__L10":     tile_type = tileType.L10; break;
        //     case "__L3210":   tile_type = tileType.L3210; break;
        //     case "__R43":     tile_type = tileType.R43; break;
        //     case "__R32":     tile_type = tileType.R32; break;
        //     case "__R21":     tile_type = tileType.R21; break;
        //     case "__R10":     tile_type = tileType.R10; break;
        //     case "__R3210":   tile_type = tileType.R3210; break;
        //     case "__M":       tile_type = tileType.M; break;
        //     case "__DL43":    tile_type = tileType.DL43; break;
        //     case "__DL32":    tile_type = tileType.DL32; break;
        //     case "__DL21":    tile_type = tileType.DL21; break;
        //     case "__DL10":    tile_type = tileType.DL10; break;
        //     case "__DL3210":  tile_type = tileType.DL3210; break;
        //     case "__DR43":    tile_type = tileType.DR43; break;
        //     case "__DR32":    tile_type = tileType.DR32; break;
        //     case "__DR21":    tile_type = tileType.DR21; break;
        //     case "__DR10":    tile_type = tileType.DR10; break;
        //     case "__DR3210":  tile_type = tileType.DR3210; break;
        //     case "__DM":      tile_type = tileType.DM; break;
        //     default: tile_type = tileType.Other; break;
        // }
    }



    // static bool check_rightPixel_overlap(Color[] current_pixels, Color[] right_pixels, int width, int x, int y){
    //     // current pixel no exist
    //     int current_pos1D = y * width + x;
    //     if (current_pixels[current_pos1D].a == 0) return false;

    //     // neighbor pixel no exist
    //     int neighbor_pos1D = y * width + x - cell_size.x;
    //     if (right_pixels[neighbor_pos1D].a == 0) return false;

    //     return true;
    // }

    // static bool check_upPixel_overlap(Color[] current_pixels, Color[] right_pixels, int width, int x, int y){
    //     // current pixel no exist
    //     int current_pos1D = y * width + x;
    //     if (current_pixels[current_pos1D].a == 0) return false;

    //     // neighbor pixel no exist
    //     int neighbor_pos1D = y * width + x - cell_size.x;
    //     if (right_pixels[neighbor_pos1D].a == 0) return false;

    //     return true;
    // }

    // static Color[] delete_alphaOverlap_up(Color[] current_pixels, Color[] right_pixels, int width, int height){
    //     for (int x = 0; x < width; x++){
    //         for (int y = cell_size.y; y < height; y++){
    //             if (check_upPixel_overlap(current_pixels, right_pixels, width, x, y)){
    //                 current_pixels[y * width + x].a = 0;
    //             }
    //         }
    //     }
    //     return current_pixels;
    // }

    // static Color[] delete_alphaOverlap_right(Color[] current_pixels, Color[] right_pixels, int width, int height){
    //     for (int y = 0; y < height; y++){
    //         for (int x = cell_size.x; x < width; x++){
    //             if (check_rightPixel_overlap(current_pixels, right_pixels, width, x, y)){
    //                 current_pixels[y * width + x].a = 0;
    //             }
    //         }
    //     }
    //     return current_pixels;
    // }

    // static Color[] delete_color_alphaOverlap(Color[] current_pixels, Tilemap tilemap, Vector3Int position, string neighbor_pos){
    //     Vector3Int offset = neighbor_pos == "right" ? new(1, 0, 0) : new(0, 1, 0);
    //     TileBase neighbor_tile = tilemap.GetTile(position + offset);
    //     // right tile is empty
    //     if (neighbor_tile == null) return current_pixels;
    //     // right tile is opaque
    //     if (neighbor_tile is Pseudo3DRuleTile tile_ && !tile_.isTransparent) return current_pixels;
    //     // placeholder is placeholder.
    //     if (neighbor_tile is Pseudo3DRuleTile tile__ && tile__.isPlaceholder) return current_pixels;

    //     // Texture2D neighbor_texture = neighbor_tile is Tile tile___ ? tile___.sprite.texture : null;
    //     Sprite neighbor_sprite = tilemap.GetSprite(position + offset);
    //     Texture2D neighbor_texture = neighbor_sprite.texture;
    //     Color[] neighbor_pixels = neighbor_texture.GetPixels((int)neighbor_sprite.rect.x, (int)neighbor_sprite.rect.y, (int)neighbor_sprite.rect.width, (int)neighbor_sprite.rect.height);
    //     // if (neighbor_pixels.Length < 2304){
    //     //     var a = 1;
    //     // }
    //     // if (neighbor_tile is Tile tile___){
    //     //     neighbor_texture = tile___.sprite.texture;
    //     // }
    //     // else{
    //     //     Debug.LogError("right_tile isn't Tile. I dont think this error will occur.");
    //     // }
    //     // Color[] neighbor_pixels = neighbor_texture.GetPixels();
    //     Color[] new_pixels = (neighbor_pos == "right") ?
    //         delete_alphaOverlap_right(current_pixels, neighbor_pixels, (int)neighbor_sprite.rect.width, (int)neighbor_sprite.rect.height) :
    //         delete_alphaOverlap_up(current_pixels, neighbor_pixels, (int)neighbor_sprite.rect.width, (int)neighbor_sprite.rect.height);

        
    //     return new_pixels;
    // }

    // static Sprite delete_sprite_alphaOverlap(Tilemap tilemap, Vector3Int position){
    //     Sprite current_sprite = tilemap.GetSprite(position);
    //     Texture2D current_texture = current_sprite.texture;

    //     Color[] current_pixels = current_texture.GetPixels((int)current_sprite.rect.x, (int)current_sprite.rect.y, (int)current_sprite.rect.width, (int)current_sprite.rect.height);

    //     Color[] new_pixels = current_pixels.Copy();
    //     new_pixels = delete_color_alphaOverlap(new_pixels, tilemap, position, "right");
    //     new_pixels = delete_color_alphaOverlap(new_pixels, tilemap, position, "up");
    //     if (new_pixels == current_pixels) return null;

    //     Texture2D new_texture = current_texture.Copy();
    //     Rect new_rect = new(0, 0, (int)current_sprite.rect.width, (int)current_sprite.rect.height);
    //     new_texture.SetPixels((int)current_sprite.rect.x, (int)current_sprite.rect.y, (int)current_sprite.rect.width, (int)current_sprite.rect.height, new_pixels);
    //     new_texture.Apply();
    //     Vector2 pivot = new(cell_size.x / 2.0f / current_texture.width, cell_size.y / 2.0f / current_texture.height);
    //     // Debug.Log(pivot);
    //     Sprite new_sprite = Sprite.Create(new_texture, new_rect, pivot);
    //     return new_sprite;
    // }

    // public static TileBase _delete_tile_alphaOverlap(Tilemap tilemap, Vector3Int position){
    //     TileBase current_tile_base = tilemap.GetTile(position);
    //     Pseudo3DRuleTile current_tile = (Pseudo3DRuleTile) current_tile_base;
    //     // opaque tile is perform well, no alpha overlap
    //     if (!current_tile.isTransparent) return null;
    //     // placeholder is placeholder.
    //     if (current_tile.isPlaceholder) return null;

    //     // Pseudo3DRuleTile right_tile = (Pseudo3DRuleTile) tilemap.GetTile(position + new Vector3Int(1, 0, 0));
    //     // Pseudo3DRuleTile up_tile = (Pseudo3DRuleTile) tilemap.GetTile(position + new Vector3Int(0, 1, 0));

    //     // RuleTile tile = current_tile_base is RuleTile tile_ ? tile_ : null;
    //     // Sprite current_pixel = tile.sprite;
    //     // Sprite current_pixel = tilemap.GetSprite(position);

    //     // Sprite new_sprite = delete_sprite_alphaOverlap(current_pixel, right_tile, up_tile);
    //     Sprite new_sprite = delete_sprite_alphaOverlap(tilemap, position);
    //     if (new_sprite != null){
    //         // tile.sprite = new_sprite;
    //         // tilemap.RefreshTile(position);
    //         Tile new_tile = ScriptableObject.CreateInstance<Tile>();
    //         new_tile.sprite = new_sprite;
    //         return new_tile;
    //         // tilemap.SetTile(position, newTile);
    //     }
    //     return null;
    // }

    // // public override void GetTileData(Vector3Int position, ITilemap tilemap, ref TileData tileData){
    // //     base.GetTileData(position, tilemap, ref tileData);
    // //     // opaque tile is perform well, no alpha overlap
    // //     if (!isTransparent) return;
    // //     // placeholder is placeholder.
    // //     if (isPlaceholder) return;

    // //     delete_alphaOverlap_right(position, tilemap, ref tileData);
    //     // Vector3Int rightPosition = new(position.x + 1, position.y, position.z);
    //     // TileBase rightTile = tilemap.GetTile(rightPosition);

    //     // if (rightTile != null){
    //     //     Sprite current_sprite = tileData.sprite;  
    //     //     Sprite right_sprite = tilemap.GetSprite(rightPosition);  

    //     //     if (current_sprite != null && right_sprite != null){
    //     //         Texture2D current_texture = current_sprite.texture;
    //     //         Texture2D right_texture = right_sprite.texture;

    //     //         Color[] current_pixels = current_texture.GetPixels();
    //     //         Color[] right_pixels = right_texture.GetPixels();

                

    //     //         for (int i = 0; i < current_pixels.Length; i++){
    //     //             if (right_pixels[i].a > 0){
    //     //                 current_pixels[i].a = 0;
    //     //             }
    //     //         }

    //     //         Texture2D newTexture = new Texture2D(current_texture.width, current_texture.height);
    //     //         newTexture.SetPixels(current_pixels);
    //     //         newTexture.Apply();

    //     //         Sprite newSprite = Sprite.Create(newTexture, current_sprite.rect, new Vector2(0.5f, 0.5f));
    //     //         tileData.sprite = newSprite;
    //     //     }
    //     // }
    // // }
}