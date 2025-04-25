using System.Collections.Generic;
using UnityEngine;

public class MatchRule{
    public string sub_ID;
    public Dictionary<TileMatchRuleType, List<Vector2Int>> rule;
    public MatchRule(string sub_ID, Dictionary<TileMatchRuleType, List<Vector2Int>> rule){
        this.sub_ID = sub_ID;
        this.rule = rule;
    }

    public bool isMatch(Vector3Int map_pos, LayerType layer){
        foreach (TileMatchRuleType ruleType in rule.Keys){
            if(!isMatchRule(map_pos, layer, ruleType, rule[ruleType])){
                return false;
            }
        }
        return true;
    }

    bool isMatchRule(Vector3Int map_pos, LayerType layer, TileMatchRuleType ruleType, List<Vector2Int> rule){
        foreach (Vector2Int offset in rule){
            if(!isMatchRule(map_pos, layer, ruleType, offset)){
                return false;
            }
        }
        return true;
    }

    bool isMatchRule(Vector3Int map_pos, LayerType layer, TileMatchRuleType ruleType, Vector2Int offset){
        Vector3Int new_pos = map_pos + new Vector3Int((int)offset.x, (int)offset.y, 0);
        if(ruleType == TileMatchRuleType.isNull){
            return !TilemapTile._check_tile(layer, new_pos);
        }
        else if(ruleType == TileMatchRuleType.notNull){
            return TilemapTile._check_tile(layer, new_pos);
        }
        return false; // shouldn't happen, just placeholder
    }
}

public enum TileMatchRuleType{
    isNull,
    notNull
}

public class TileMatchRule{
    public static List<MatchRule> match_rules = new(){
        new("__L43", new (){ // 1
            {TileMatchRuleType.isNull, new(){new(-4, 0), new(-3, 1), new(-2, 1), new(-1, 1), new(0, 1) }},
            {TileMatchRuleType.notNull, new(){new(-3, 0), new(-2, 0), new(-1, 0), new(1, 0), new(2, 0), new(3, 0), new(4, 0) } }
        }),
        new("__L32", new (){ // 2
            {TileMatchRuleType.isNull, new(){new(-3, 0), new(-2, 1), new(-1, 1), new(0, 1) }},
            {TileMatchRuleType.notNull, new(){new(-2, 0), new(-1, 0), new(1, 0), new(2, 0), new(3, 0) } }
        }),
        new("__L32", new (){ // 3
            {TileMatchRuleType.isNull, new(){new(-2, 0), new(-1, 1), new(0, 1), new(1, 1), new(3, 0) }},
            {TileMatchRuleType.notNull, new(){new(-1, 0), new(1, 0), new(2, 0) } }
        }),
        new("__L32", new (){ // 4
            {TileMatchRuleType.isNull, new(){new(-2, 0), new(-1, 1), new(0, 1) }},
            {TileMatchRuleType.notNull, new(){new(-1, 0), new(1, 0), new(2, 0), new(1, 1) } }
        }),
        new("__L32", new (){ // 5
            {TileMatchRuleType.isNull, new(){new(-2, 0), new(-1, 1), new(0, 1), new(4, 0) }},
            {TileMatchRuleType.notNull, new(){new(-1, 0), new(1, 0), new(2, 0), new(3, 0) } }
        }),
        new("__L21", new (){ // 6
            {TileMatchRuleType.isNull, new(){new(-2, 0), new(-1, 1), new(0, 1), new(1, 1) }},
            {TileMatchRuleType.notNull, new(){new(-1, 0), new(1, 0), new(2, 0), new(3, 0), new(4, 0) } }
        }),
        new("__L10", new (){ // 7
            {TileMatchRuleType.isNull, new(){new(-1, 0), new(0, 1), new(1, 1) }},
            {TileMatchRuleType.notNull, new(){new(1, 0), new(2, 0), new(3, 0) } }
        }),
        new("__L3210", new (){ // 8
            {TileMatchRuleType.isNull, new(){new(-1, 0), new(0, 1) }},
            {TileMatchRuleType.notNull, new(){new(1, 0) } }
        }),
        new("__M", new (){ // 9
            {TileMatchRuleType.isNull, new(){new(-1, 0), new(0, 1), new(1, 0) }},
        }),
        new("__R43", new (){ // 10
            {TileMatchRuleType.isNull, new(){new(0, 1), new(1, 1), new(2, 1), new(3, 1), new(4, 0) }},
            {TileMatchRuleType.notNull, new(){new(-4, 0), new(-3, 0), new(-2, 0), new(-1, 0), new(1, 0), new(2, 0), new(3, 0) } }
        }),
        new("__R32", new (){ // 11
            {TileMatchRuleType.isNull, new(){new(0, 1), new(1, 1), new(2, 1), new(3, 0) }},
            {TileMatchRuleType.notNull, new(){new(-3, 0), new(-2, 0), new(-1, 0), new(1, 0), new(2, 0) } }
        }),
        new("__R32", new (){ // 12
            {TileMatchRuleType.isNull, new(){new(-2, 0), new(-1, 1), new(0, 1), new(1, 1), new(2, 0) }},
            {TileMatchRuleType.notNull, new(){new(-2, 0), new(-1, 0), new(1, 0) } }
        }),
        new("__R32", new (){ // 13
            {TileMatchRuleType.isNull, new(){new(0, 1), new(1, 1), new(2, 0) }},
            {TileMatchRuleType.notNull, new(){new(-2, 0), new(-1, 0), new(-1, 1), new(1, 0) } }
        }),
        new("__R32", new (){ // 14
            {TileMatchRuleType.isNull, new(){new(-4, 0), new(0, 1), new(1, 1), new(2, 0) }},
            {TileMatchRuleType.notNull, new(){new(-3, 0), new(-2, 0), new(-1, 0), new(1, 0) } }
        }),
        new("__R21", new (){ // 15
            {TileMatchRuleType.isNull, new(){new(-1, 1), new(0, 1), new(1, 1), new(2, 0) }},
            {TileMatchRuleType.notNull, new(){new(-2, 0), new(-1, 0), new(1, 0) } }
        }),
        new("__R10", new (){ // 16
            {TileMatchRuleType.isNull, new(){new(-1, 1), new(0, 1), new(1, 0)}},
            {TileMatchRuleType.notNull, new(){new(-3, 0), new(-2, 0), new(-1, 0) } }
        }),
        new("__R3210", new (){ // 17
            {TileMatchRuleType.isNull, new(){new(0, 1), new(1, 0) }},
            {TileMatchRuleType.notNull, new(){new(-1, 0) } }
        }),
        new("__DL3210", new (){ // 18
            {TileMatchRuleType.isNull, new(){new(-1, 0), new(0, -1) }},
            {TileMatchRuleType.notNull, new(){new(0, 1), new(1, 0)} }
        }),
        new("__DR3210", new (){ // 19
            {TileMatchRuleType.isNull, new(){new(0, -1), new(1, 0) }},
            {TileMatchRuleType.notNull, new(){new(-1, 0), new(0, 1) } }
        }),
        new("__DM", new (){ // 20
            {TileMatchRuleType.isNull, new(){new(-1, 0), new(0, -1), new(1, 0)}},
            {TileMatchRuleType.notNull, new(){new(0, 1) } }
        }),
        new("__Full", new ())
    };


    public TileMatchRule(){

    }


    public static void match(Vector3Int map_pos, LayerType layer){
        for(int i = 0; i < match_rules.Count; i++){
            MatchRule rule = match_rules[i];
            if (rule.isMatch(map_pos, layer)){
                TilemapTile tile = TilemapTile._get(layer, map_pos);
                tile._set_subID(rule.sub_ID);
                tile._update_tile();
                break;
            }
        }
    }
}