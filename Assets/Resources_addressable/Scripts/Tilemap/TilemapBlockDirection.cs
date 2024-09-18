using System.Collections.Generic;
using System.Linq;
// using System;
using Unity.VisualScripting;
using UnityEngine;


struct _DirectionsInfo{
    public string[] direction;
    public string ID;
    public string[] up;
    public string[] down;
    public string[] left;
    public string[] right;
}

    /*  ---------- surface direction ----------
     *  ┌-----┬-----┬-----┐
     *  │__777│_____│999__│ I label these directions with numbers 
     *  │_7777│88888│9999_│     corresponding to the number pad positions for the block's solid area.
     *  │77777│88888│99999│ For example, 
     *  ├-----┼-----┼-----┤     1 in left-down, only left-down tiles are solid, i.e. from left to down
     *  │4____│55555│____6│     4 in left, the tiles in left are solid, i.e. from up-left to down-right
     *  │44___│55555│___66│     7,9 are opposite which denotes the empty area
     *  │444__│55555│__666│
     *  ├-----┼-----┼-----┤ Besides, _ means the reverse version
     *  │_____│_____│_____│
     *  │1____│22222│____3│
     *  │11___│22222│___33│
     *  └-----┴-----┴-----┘
     *  0. [empty, ]           : no tile in this block
     *  1. [left, down]        : from left to down
     *  2. [horizontal, ]      : from left to right
     *  3. [right, down]       : from right to down
     *  4. [vertical, left]    : from up-left to down-right
     *  5. [full, ]            : all tiles are soild
     *  6. [vertical, right]   : from up-right to down-left
     *  7. [left, up]          : from left to up
     *  8. [horizontal, ]      : 8. == 2.
     *  9. [right, up]         : from right to up
     * 
     *  ---------- reverse direction ----------
     *  10. [_empty, ]         : the reverse version of 0.
     *  11. [_left, down]      : the reverse version of 1.
     *  12. _2
     *  13. _3
     *  14. _4
     *  15. _5
     *  16. _6
     *  17. _7
     *  18. _8
     *  19. _9
     *  
     *  ---------- direction relation ----------
     * If direction of this block is 'x', which block can connect it?
     *  ┌-----┬-----┬-----┐       ┌-----┬-----┬-----┐       ┌-----┬-----┬-----┐
     *  │     │ 3 6 │     │       │     │     │     │       │     │ 1 4 │     │
     *  │     │_1 4 │     │       │     │     │     │       │     │_3 6 │     │
     *  ├-----┼-----┼-----┤       ├-----┼-----┼-----┤       ├-----┼-----┼-----┤
     *  │ 239 │  7  │ 459 │       │     │  2  │     │       │ 567 │  9  │ 127 │
     *  │     │     │_3 6 │       │     │     │     │       │_1 4 │     │     │
     *  ├-----┼-----┼-----┤       ├-----┼-----┼-----┤       ├-----┼-----┼-----┤
     *  │     │  5  │     │       │     │     │     │       │     │  5  │     │
     *  │     │_123 │     │       │     │     │     │       │     │_123 │     │
     *  └-----┴-----┴-----┘       └-----┴-----┴-----┘       └-----┴-----┴-----┘
     * 
     *  ┌-----┬-----┬-----┐       ┌-----┬-----┬-----┐       ┌-----┬-----┬-----┐
     *  │     │ 1 4 │     │       │     │ 279 │     │       │     │ 3 6 │     │
     *  │     │_3 6 │     │       │     │     │     │       │     │_1 4 │     │
     *  ├-----┼-----┼-----┤       ├-----┼-----┼-----┤       ├-----┼-----┼-----┤
     *  │ 567 │  4  │ 036 │       │ 6 7 │  5* │ 4 9 │       │ 014 │  6  │ 459 │
     *  │_1 4 │     │_4 9 │       │_1 4 │     │_3 6 │       │_6 7 │     │_3 6 │
     *  ├-----┼-----┼-----┤       ├-----┼-----┼-----┤       ├-----┼-----┼-----┤
     *  │     │ 4 9 │     │       │     │     │     │       │     │ 6 7 │     │
     *  │     │_6 7 │     │       │     │_123 │     │       │     │_4 9 │     │
     *  ├-----┼-----┼-----┤       ├-----┼-----┼-----┤       ├-----┼-----┼-----┤
     * 
     *  ┌-----┬-----┬-----┐       ┌-----┬-----┬-----┐       ┌-----┬-----┬-----┐
     *  │     │  0  │     │       │     │  0  │     │       │     │  0  │     │
     *  │     │_279 │     │       │     │_279 │     │       │     │_279 │     │
     *  ├-----┼-----┼-----┤       ├-----┼-----┼-----┤       ├-----┼-----┼-----┤
     *  │ 239 │  1  │ 036 │       │ 239 │  2  │ 127 │       │ 014 │  3  │ 127 │
     *  │     │     │_4 9 │       │     │     │     │       │_6 7 │     │     │
     *  ├-----┼-----┼-----┤       ├-----┼-----┼-----┤       ├-----┼-----┼-----┤
     *  │     │ 4 9 │     │       │     │  5  │     │       │     │ 6 7 │     │
     *  │     │_6 7 │     │       │     │_123 │     │       │     │_4 9 │     │
     *  ├-----┼-----┼-----┤       ├-----┼-----┼-----┤       ├-----┼-----┼-----┤
     * 
     *  ┌-----┬-----┬-----┐
     *  │     │     │     │   x*: around with x
     *  │     │_279 │     │
     *  ├-----┼-----┼-----┤
     *  │ 1 4 │  0* │ 3 6 │
     *  │_6 7 │     │_4 9 │
     *  ├-----┼-----┼-----┤
     *  │     │ 123 │     │
     *  │     │     │     │
     *  ├-----┼-----┼-----┤
     * 
     *  ---------- reverse relation ----------
     *  
     *  ┌-----┬-----┬-----┐       ┌-----┬-----┬-----┐       ┌-----┬-----┬-----┐
     *  │     │ 1 4 │     │       │     │     │     │       │     │ 3 6 │     │
     *  │     │_3 6 │     │       │     │     │     │       │     │_1 4 │     │
     *  ├-----┼-----┼-----┤       ├-----┼-----┼-----┤       ├-----┼-----┼-----┤
     *  │     │ _7  │ 036 │       │     │ _2  │     │       │ 014 │ _9  │     │
     *  │_239 │     │_4 9 │       │     │     │     │       │_6 7 │     │_127 │
     *  ├-----┼-----┼-----┤       ├-----┼-----┼-----┤       ├-----┼-----┼-----┤
     *  │     │0123 │     │       │     │     │     │       │     │0123 │     │
     *  │     │     │     │       │     │     │     │       │     │     │     │
     *  └-----┴-----┴-----┘       └-----┴-----┴-----┘       └-----┴-----┴-----┘
     * 
     *  ┌-----┬-----┬-----┐       ┌-----┬-----┬-----┐       ┌-----┬-----┬-----┐
     *  │     │ 3 6 │     │       │     │     │     │       │     │ 1 4 │     │
     *  │     │_1 4 │     │       │     │     │     │       │     │_3 6 │     │
     *  ├-----┼-----┼-----┤       ├-----┼-----┼-----┤       ├-----┼-----┼-----┤
     *  │ 014 │ _4  │ 459 │       │     │  0  │     │       │ 567 │ _6  │ 036 │
     *  │_6 7 │     │_3 6 │       │     │     │     │       │_1 4 │     │_4 9 │
     *  ├-----┼-----┼-----┤       ├-----┼-----┼-----┤       ├-----┼-----┼-----┤
     *  │     │ 6 7 │     │       │     │     │     │       │     │ 4 9 │     │
     *  │     │_4 9 │     │       │     │     │     │       │     │_6 7 │     │
     *  ├-----┼-----┼-----┤       ├-----┼-----┼-----┤       ├-----┼-----┼-----┤
     * 
     *  ┌-----┬-----┬-----┐       ┌-----┬-----┬-----┐       ┌-----┬-----┬-----┐
     *  │     │ 2579│     │       │     │ 2579│     │       │     │ 2579│     │
     *  │     │     │     │       │     │     │     │       │     │     │     │
     *  ├-----┼-----┼-----┤       ├-----┼-----┼-----┤       ├-----┼-----┼-----┤
     *  │     │ _1  │ 459 │       │     │ _2  │     │       │ 567 │ _3  │     │
     *  │_239 │     │_3 6 │       │_239 │     │_127 │       │_1 4 │     │_127 │
     *  ├-----┼-----┼-----┤       ├-----┼-----┼-----┤       ├-----┼-----┼-----┤
     *  │     │ 6 7 │     │       │     │0123 │     │       │     │ 4 9 │     │
     *  │     │_4 9 │     │       │     │     │     │       │     │_6 7 │     │
     *  ├-----┼-----┼-----┤       ├-----┼-----┼-----┤       ├-----┼-----┼-----┤
     * 
     *  
     *  ---------- Additional directions ----------
     *  [error, ]           : relation error
     * 
     * 
     *  ---------- terrain ----------
     *  plain: 左右走向的平原
     *  
     */
class DirectionsConfig{
    static _DirectionsInfo[] directions_info = new _DirectionsInfo[] { 
        new _DirectionsInfo{ ID = "0", direction = new string[] {"empty", ""},
            up = new string[]{"0", "12", "17", "19"},
            down = new string[]{"0", "1", "2", "3"},
            left = new string[]{"0", "1", "4", "16", "17"}, 
            right = new string[]{"0", "3", "6", "14", "19"}, 
        },
        new _DirectionsInfo{ ID = "1", direction = new string[] {"left", "down"},
            up = new string[]{"0", "12", "17", "19"},              
            down = new string[]{"4", "9", "16", "17"},         
            left = new string[]{"2", "3", "9"},      
            right = new string[]{"0", "3", "6", "14", "19"},     
        },
        new _DirectionsInfo{ ID = "2", direction = new string[] {"horizontal", ""}, 
            up = new string[]{"0", "12", "17", "19"},              
            down = new string[]{"5", "11", "12", "13"},            
            left = new string[]{"2", "3", "9"},      
            right = new string[]{"1", "2", "7"},     
        },
        new _DirectionsInfo{ ID = "3", direction = new string[] {"right", "down"},
            up = new string[]{"0", "12", "17", "19"},              
            down = new string[]{"6", "7", "14", "19"},         
            left = new string[]{"0", "1", "4", "16", "17"},      
            right = new string[]{"1", "2", "7"},     
        },
        new _DirectionsInfo{ ID = "4", direction = new string[] {"vertical", "left"},
            up = new string[]{"1", "4", "13", "16"},           
            down = new string[]{"4", "9", "16", "17"},         
            left = new string[]{"5", "6", "7", "11", "14"},      
            right = new string[]{"0", "3", "6", "14", "19"},     
        },
        new _DirectionsInfo{ ID = "5", direction = new string[] {"full", ""},
            up = new string[]{"2", "5", "7", "9"},     
            down = new string[]{"5", "11", "12", "13"},            
            left = new string[]{"5", "6", "7", "11", "14"},      
            right = new string[]{"4", "5", "9", "13", "16"},
        },
        new _DirectionsInfo{ ID = "6", direction = new string[] {"vertical", "right"},
            up = new string[]{"3", "6", "11", "14"},
            down = new string[]{"6", "7", "14", "19"},
            left = new string[]{"0", "1", "4", "16", "17"},
            right = new string[]{"4", "5", "9", "13", "16"},
        },
        new _DirectionsInfo{ ID = "7", direction = new string[] {"left", "up"},
            up = new string[]{"3", "6", "11", "14"},           
            down = new string[]{"5", "11", "12", "13"},            
            left = new string[]{"2", "3", "9"},      
            right = new string[]{"4", "5", "9", "13", "16"},     
        },
        new _DirectionsInfo{ ID = "8", direction = new string[] {"horizontal", ""}
        }, // ID 8 == ID 2
        new _DirectionsInfo{ ID = "9", direction = new string[] {"right", "up"},
            up = new string[]{"1", "4", "13", "16"},           
            down = new string[]{"5", "11", "12", "13"},            
            left = new string[]{"5", "6", "7", "11", "14"},      
            right = new string[]{"1", "2", "7"},     
        },
        // 10-19 is the reverse version of 0-9, and 10, 15, 18 are abandon because they are repeat
        new _DirectionsInfo{ ID = "10", direction = new string[] {"_empty", ""},
        }, // ID 10 == ID 5
        new _DirectionsInfo{ ID = "11", direction = new string[] {"_left", "down"},
            up = new string[]{"2", "5", "7", "9"},              
            down = new string[]{"6", "7", "14", "19"},         
            left = new string[]{"12", "13", "19"},      
            right = new string[]{"4", "5", "9", "13", "16"},     
        },
        new _DirectionsInfo{ ID = "12", direction = new string[] {"_horizontal", ""}, 
            up = new string[]{"2", "5", "7", "9"},              
            down = new string[]{"0", "1", "2", "3"},            
            left = new string[]{"12", "13", "19"},      
            right = new string[]{"11", "12", "17"},     
        },
        new _DirectionsInfo{ ID = "13", direction = new string[] {"_right", "down"},
            up = new string[]{"2", "5", "7", "9"},              
            down = new string[]{"4", "9", "16", "17"},         
            left = new string[]{"5", "6", "7", "11", "14"},      
            right = new string[]{"11", "12", "17"},     
        },
        new _DirectionsInfo{ ID = "14", direction = new string[] {"_vertical", "left"},
            up = new string[]{"3", "6", "11", "14"},           
            down = new string[]{"6", "7", "14", "19"},         
            left = new string[]{"1", "4", "16", "17"},      
            right = new string[]{"4", "5", "9", "13", "16"},     
        },
        new _DirectionsInfo{ ID = "15", direction = new string[] {"_full", ""},
        }, // ID 15 == ID 0
        new _DirectionsInfo{ ID = "16", direction = new string[] {"_vertical", "right"},
            up = new string[]{"1", "4", "13", "16"},           
            down = new string[]{"4", "9", "16", "17"},         
            left = new string[]{"5", "6", "7", "11", "14"},      
            right = new string[]{"0", "3", "6", "14", "19"},     
        },
        new _DirectionsInfo{ ID = "17", direction = new string[] {"_left", "up"},
            up = new string[]{"1", "4", "13", "16"},           
            down = new string[]{"1", "2", "3"},            
            left = new string[]{"12", "13", "19"},      
            right = new string[]{"3", "6", "14", "19"},     
        }, 
        new _DirectionsInfo{ ID = "18", direction = new string[] {"_horizontal", ""}, 
        }, // ID 18 == ID 12
        new _DirectionsInfo{ ID = "19", direction = new string[] {"_right", "up"},
            up = new string[]{"3", "6", "11", "14"},           
            down = new string[]{"1", "2", "3"},            
            left = new string[]{"1", "4", "16", "17"},      
            right = new string[]{"11", "12", "17"},     
        }
    };

    public string[] _random_direction(TilemapBlockAround around_blocks, TilemapBlock block, TilemapTerrain terrain){
        // ----- get available directions FROM terrain type of block
        TerrainHier2Info terrain_type = terrain.tags2TerrainHier2[block.terrain_tags];
        string[] dirs_avail = get_available_directions(around_blocks, terrain_type.dirs_avail);
        // no available direction, throw the "error" direction
        if (dirs_avail.Length == 0) return new string[]{"error", ""};
        // ----- get probability of available direction
        float[] dirs_prob = new float[dirs_avail.Length];
        int dir_index;
        for (int i = 0; i < dirs_avail.Length; i++){
            dir_index = System.Array.IndexOf(terrain_type.dirs_avail, dirs_avail[i]);
            dirs_prob[i] = terrain_type.dirs_prob[dir_index];
        }
        // ----- random a direction
        string direction_ID = dirs_avail[random_by_prob(dirs_prob, block.offsets)];
        string[] direction = mapping_ID_to_directionInfo(direction_ID).direction;
        return direction;
    }

    int random_by_prob(float[] probs, Vector3Int offsets){
        float sum = probs.Sum();
        int random_offset = offsets.x + offsets.y;
        float target = Random.Range(random_offset, sum + random_offset) - random_offset;
        for(int i = 0; i < probs.Length; i++){
            target -= probs[i];
            if(target <= 0){
                return i;
            }
        }
        return probs.Length - 1;
    }

    _DirectionsInfo mapping_ID_to_directionInfo(string ID){
        for (int i = 0; i < directions_info.Length; i++){
            if(directions_info[i].ID == ID)
                return directions_info[i];
        }
        return new();   // error
    }

    string[] get_available_directions(TilemapBlockAround around_blocks, string[] availables){
        // get available directions FROM around blocks (i.e., adjecent blocks)
        // get available directions FROM intersect between this and adjecent block
        if(around_blocks.up.isExist){
            int direction_index = mapping_direction_to_index(around_blocks.up.direction);
            string[] avail = directions_info[direction_index].down;
            availables = availables.Intersect(avail).ToArray();
        }
        if(around_blocks.down.isExist){
            int direction_index = mapping_direction_to_index(around_blocks.down.direction);
            string[] avail = directions_info[direction_index].up;
            availables = availables.Intersect(avail).ToArray();
        }
        if(around_blocks.left.isExist){
            int direction_index = mapping_direction_to_index(around_blocks.left.direction);
            string[] avail = directions_info[direction_index].right;
            availables = availables.Intersect(avail).ToArray();
        }
        if(around_blocks.right.isExist){
            int direction_index = mapping_direction_to_index(around_blocks.right.direction);
            string[] avail = directions_info[direction_index].left;
            availables = availables.Intersect(avail).ToArray();
        }
        return availables;
    }

    int mapping_direction_to_index(string[] direction){
        for(int i = 0; i < directions_info.GetLength(0); i++)
            if(direction[0] == directions_info[i].direction[0] && direction[1] == directions_info[i].direction[1])
                return i;
        return -1;
    }
}


public class TilemapBlockDirection{
    // TilemapConfig _tilemap_base;
    // GameConfigs GCfg;
    DirectionsConfig DirCfg = new();

    // public TilemapBlockDirection(TilemapConfig tilemap_base, GameConfigs game_configs){
    //     _tilemap_base = tilemap_base;
    //     GCfg = game_configs;
    // }

    public TilemapBlock _random_direction(
            TilemapBlock block, 
            TilemapBlockAround around_blocks, 
            TilemapTerrain terrain, 
            Vector3Int[] extra_groundPos, 
            string[] direction){
        int random_offset_1 = block.offsets.x + block.offsets.y + 100;
        int random_offset_2 = block.offsets.x + block.offsets.y - 100;
        Vector3Int BSize = block.size;    // for convenience
        int min_h = 1;        // min_h also means boundBottom_h or boundTop_h
        int max_h = BSize.y - min_h;
        int min_w = 1;
        int max_w = BSize.x - min_w;
        // if (direction[0] == "random"){
        //     direction = _directions_config.select_direction_random(around_blocks);
        // }
        direction ??= DirCfg._random_direction(around_blocks, block, terrain);
        block.direction = direction;
        block.up = new(-1, BSize.y);
        block.down = new(-1, 0);
        block.left = new(0, -2);
        block.right = new(BSize.x - 1, -1);
        // ----- Reverse mode
        if (direction[0][0] == '_'){
            block.direction_reverse = true;
            string[] _direction = direction.ToArray();
            _direction[0] = direction[0].Substring(1);
            direction = _direction;
        }
        // ---------- target ----------
        block.groundPos = new();
        if (extra_groundPos != null)
            for(int i = 0; i < extra_groundPos.Length; i++){
                block.groundPos.Add(extra_groundPos[i]);
            }
        if (direction[0] == "error"){
            for (int i = 0; i < BSize.x; i++){
                if (i % 2 == 0)
                    block.groundPos.Add(new(i, BSize.y));
                else
                    block.groundPos.Add(new(i, 1));
            }
            block.isExist = false;
        }
        if (direction[0] == "horizontal"){
            if (around_blocks.left.isExist && around_blocks.right.isExist) {
                block.left.y = around_blocks.left.right.y;
                block.right.y = around_blocks.right.left.y;
            } else if (around_blocks.left.isExist){
                block.left.y = around_blocks.left.right.y;
                block.right.y = Random.Range(min_h + random_offset_1, max_h + random_offset_1) - random_offset_1;
            } else if (around_blocks.right.isExist){
                block.left.y = Random.Range(min_h + random_offset_1, max_h + random_offset_1) - random_offset_1;
                block.right.y = around_blocks.right.left.y;
            } else{
                block.left.y = Random.Range(min_h + random_offset_1, max_h + random_offset_1) - random_offset_1;
                block.right.y = Random.Range(min_h + random_offset_2, max_h + random_offset_2) - random_offset_2;
            }
            // ---------- for extra groundPos
            if (extra_groundPos != null){
                if (extra_groundPos[0].x == 0) block.left.y = extra_groundPos[0].y;
                if (extra_groundPos[0].x == BSize.x-1) block.left.y = extra_groundPos[0].y;
            }
            // ---------- normal
            block.groundPos.Add(block.left);
            block.groundPos.Add(block.right);
        }
        else if (direction[0] == "vertical"){
            if (direction[1] == "left"){
                if (around_blocks.up.isExist && around_blocks.down.isExist) {
                    block.up.x = around_blocks.up.down.x;
                    block.down.x = around_blocks.down.up.x;
                } else if (around_blocks.up.isExist){
                    block.up.x = around_blocks.up.down.x;
                    block.down.x = Random.Range(block.up.x + random_offset_1, max_w + random_offset_1) - random_offset_1;
                } else if (around_blocks.down.isExist){
                    block.down.x = around_blocks.down.up.x;
                    block.up.x = Random.Range(min_w + random_offset_1, block.down.x + random_offset_1) - random_offset_1;
                } else {
                    block.up.x = Random.Range(min_w + random_offset_1, max_w + random_offset_1) - random_offset_1;
                    block.down.x = Random.Range(block.up.x + random_offset_2, max_w + random_offset_2) - random_offset_2;
                }
                block.groundPos.Add(new(0, BSize.y));
                block.groundPos.Add(block.up);
                block.groundPos.Add(block.down);
                block.groundPos.Add(new(BSize.x-1, 0));
            }
            else if (direction[1] == "right"){
                if (around_blocks.up.isExist && around_blocks.down.isExist) {
                    block.up.x = around_blocks.up.down.x;
                    block.down.x = around_blocks.down.up.x;
                } else if (around_blocks.up.isExist){
                    block.up.x = around_blocks.up.down.x;
                    block.down.x = Random.Range(min_w + random_offset_1, block.up.x + random_offset_1) - random_offset_1;
                } else if (around_blocks.down.isExist){
                    block.down.x = around_blocks.down.up.x;
                    block.up.x = Random.Range(block.down.x + random_offset_1, max_w + random_offset_1) - random_offset_1;
                } else {
                    block.up.x = Random.Range(min_w + random_offset_1, max_w + random_offset_1) - random_offset_1;
                    block.down.x = Random.Range(min_w + random_offset_2, block.up.x + random_offset_2) - random_offset_2;
                }
                block.groundPos.Add(new(0, 0));
                block.groundPos.Add(block.down);
                block.groundPos.Add(block.up);
                block.groundPos.Add(new(BSize.x-1, BSize.y));
            }
        }
        else if (direction[0] == "left"){
            if (direction[1] == "up") {
                if (around_blocks.left.isExist && around_blocks.up.isExist) {
                    block.left.y = around_blocks.left.right.y;
                    block.up.x = around_blocks.up.down.x;
                } else if (around_blocks.left.isExist) {
                    block.left.y = around_blocks.left.right.y;
                    block.up.x = Random.Range(min_w + random_offset_1, max_w + random_offset_1) - random_offset_1;
                } else if (around_blocks.up.isExist) {
                    block.left.y = Random.Range(min_h + random_offset_1, max_h + random_offset_1) - random_offset_1;
                    block.up.x = around_blocks.up.down.x;
                } else {
                    block.left.y = Random.Range(min_h + random_offset_1, max_h + random_offset_1) - random_offset_1;
                    block.up.x = Random.Range(min_w + random_offset_2, max_w + random_offset_2) - random_offset_2;
                }
                block.groundPos.Add(block.left);
                block.groundPos.Add(block.up);
                block.groundPos.Add(new(BSize.x - 1, BSize.y));
            }
            else if (direction[1] == "down") {
                if (around_blocks.left.isExist && around_blocks.down.isExist) {
                    block.left.y = around_blocks.left.right.y;
                    block.down.x = around_blocks.down.up.x;
                } else if (around_blocks.left.isExist) {
                    block.left.y = around_blocks.left.right.y;
                    block.down.x = Random.Range(min_w + random_offset_1, max_w + random_offset_1) - random_offset_1;
                } else if (around_blocks.down.isExist) {
                    block.left.y = Random.Range(min_h + random_offset_1, max_h + random_offset_1) - random_offset_1;
                    block.down.x = around_blocks.down.up.x;
                } else {
                    block.left.y = Random.Range(min_h + random_offset_1, max_h + random_offset_1) - random_offset_1;
                    block.down.x = Random.Range(min_w + random_offset_2, max_w + random_offset_2) - random_offset_2;
                }
                block.groundPos.Add(block.left);
                block.groundPos.Add(block.down);
                block.groundPos.Add(new(BSize.x - 1, 0));
            }
        }
        else if (direction[0] == "right"){
            if (direction[1] == "up"){
                if (around_blocks.right.isExist && around_blocks.up.isExist) {
                    block.right.y = around_blocks.right.left.y;
                    block.up.x = around_blocks.up.down.x;
                } else if (around_blocks.right.isExist) {
                    block.right.y = around_blocks.right.left.y;
                    block.up.x = Random.Range(min_w + random_offset_1, max_w + random_offset_1) - random_offset_1;
                } else if (around_blocks.up.isExist) {
                    block.right.y = Random.Range(min_h + random_offset_1, max_h + random_offset_1) - random_offset_1;
                    block.up.x = around_blocks.up.down.x;
                } else{
                    block.right.y = Random.Range(min_h + random_offset_1, max_h + random_offset_1) - random_offset_1;
                    block.up.x = Random.Range(min_w + random_offset_2, max_w + random_offset_2) - random_offset_2;
                }
                block.groundPos.Add(new(0, BSize.y));
                block.groundPos.Add(block.up);
                block.groundPos.Add(block.right);
            }
            else if (direction[1] == "down"){
                if (around_blocks.right.isExist && around_blocks.down.isExist) {
                    block.right.y = around_blocks.right.left.y;
                    block.down.x = around_blocks.down.up.x;
                } else if (around_blocks.right.isExist) {
                    block.right.y = around_blocks.right.left.y;
                    block.down.x = Random.Range(min_w + random_offset_1, max_w + random_offset_1) - random_offset_1;
                } else if (around_blocks.down.isExist) {
                    block.right.y = Random.Range(min_h + random_offset_1, max_h + random_offset_1) - random_offset_1;
                    block.down.x = around_blocks.down.up.x;
                } else {
                    block.right.y = Random.Range(min_h + random_offset_1, max_h + random_offset_1) - random_offset_1;
                    block.down.x = Random.Range(min_w + random_offset_2, max_w + random_offset_2) - random_offset_2;
                }
                block.groundPos.Add(new(0, 0));
                block.groundPos.Add(block.down);
                block.groundPos.Add(block.right);
            }
        }
        else if (direction[0] == "full"){
            block.left.y = BSize.y;
            block.right.y = BSize.y;
            block.groundPos.Add(block.left);
            block.groundPos.Add(block.right);
        }
        else if (direction[0] == "empty"){
            block.left.y = 0;
            block.right.y = 0;
            block.groundPos.Add(block.left);
            block.groundPos.Add(block.right);
        }
        return block;
    }

    

}

