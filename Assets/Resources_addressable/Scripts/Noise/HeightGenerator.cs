using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;


public class HeightGenerator{
    struct _Tile{
        public int x;       // target x
        public int y;       // target y
        public int perlin;  // perlin result which need to transit to target y
    }
    List<_Tile> _tiles = new();
    TilemapBlock _block;
    Vector3Int _BSize;

    // public _HeightGenerator(TilemapBlock block){
    //     _block = block;
    //     _BSize = block.size;
    // }
    
    public HeightGenerator(TilemapBlock block, Vector3Int block_size=new()){
        _block = block;
        if (block_size.x == 0 && block_size.y == 0)_BSize = block.size;
        else _BSize = block_size;
    }

    public void _Add(Vector3Int tile_pos){
        // sort
        int insert_index = _tiles.FindIndex(tile => tile.x >= tile_pos.x);
        if (insert_index == -1) insert_index = _tiles.Count;
        // insert
        int perlin = get_perlin(tile_pos.x);
        _Tile tile = new(){x=tile_pos.x, y=tile_pos.y, perlin=perlin};
        _tiles.Insert(insert_index, tile);
    }

    public int _get_height(int x){
        _Tile tile_left = new();
        _Tile tile_right = new();
        // Find pos: (left.x, x, right.x)
        for (int i=1; i<_tiles.Count; i++){
            tile_right = _tiles[i];
            if (tile_right.x >= x ){
                tile_left = _tiles[i-1];
                break;
            }
        }
        int perlin = get_height(tile_left, tile_right, x);
        return perlin;
    }

    int get_perlin(int x){
        // int perlin = Mathf.CeilToInt((_max_h - _min_h) * Mathf.PerlinNoise((x + _base_x)/_scale, 0f)) + _min_h;
        // int perlin = Mathf.CeilToInt(_block_h * Mathf.PerlinNoise((x + _base_x)/_scale, 0f));
        int perlin = Mathf.CeilToInt(_BSize.y * _block._perlin(x));
        return perlin;
    }

    int get_height(_Tile left, _Tile right, int x){
        int perlin = get_perlin(x);
        perlin = limit_target_h(x, perlin, left, right);
        perlin = limit_top_or_bottom(x, perlin, left, right);
        // perlin = _limit_min_h(x, perlin, left, right);
        // perlin = _limit_max_h(x, perlin, left, right);
        return perlin;
    }
    
    // ---------- limit format ----------
    int limit_target_h(int x, int y, _Tile left, _Tile right){
        float diff_a = left.y - left.perlin;
        float diff_b = right.y - right.perlin;
        float distance = right.x - left.x;
        float transition_h = (diff_b - diff_a) / distance * (x - left.x) + diff_a;
        int result = y + Mathf.CeilToInt(transition_h);
        return result;
    }

    int limit_top_or_bottom(int x, int y, _Tile left, _Tile right){
        if (left.y == _BSize.y && right.y == _BSize.y)
            return _BSize.y;
        else if (left.y == 0 && right.y == 0)
            return 0;
        else
            return y;
    }

    // int _limit_min_h(int x, int y, _Tile left, _Tile right){
    //     int min_distance = ((right.x-x) < (x-left.x)) ? right.x-x : x-left.x;
    //     int min_h = Mathf.CeilToInt(_block_h * _bound_h_ratio);
    //     // Above minimum height
    //     if (y >= min_h)
    //         return y;
    //     // limit function for min_h with slope 1, i.e., when min_distance > min_h, directly corrected to min_h
    //     y = (min_distance < min_h) ? min_distance : min_h;
    //     return y;
    // }

    // int _limit_max_h(int x, int y, _Tile left, _Tile right){
    //     int min_distance = ((right.x-x) < (x-left.x)) ? right.x-x : x-left.x;
    //     int min_h = Mathf.CeilToInt(_block_h * _bound_h_ratio);
    //     int max_h = Mathf.CeilToInt(_block_h * (1 - _bound_h_ratio));
    //     // Below maximum height
    //     if (y <= max_h)
    //         return y;
    //     // limit function for max_h with slope 1, i.e., when max_distance > bound_h, directly corrected to max_h
    //     y = (min_distance < min_h) ? _block_h - min_distance : max_h;
    //     return y;
    // }
}
