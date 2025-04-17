using System.Collections;
using System.Collections.Generic;
using System;
using System.Threading;
using UnityEngine;
using UnityEngine.Tilemaps;
using Cysharp.Threading.Tasks;
using Unity.VisualScripting;

public class ObjectAbilMoveJump: ObjectAbilMoveBase{
    public ObjectAbilMoveJump(ObjectConfig config, float cooldown, float wait, int uses): this(config, cooldown, wait, uses, -1){}
    public ObjectAbilMoveJump(ObjectConfig config, float cooldown, float wait, float duration): this(config, cooldown, wait, -1, duration){}
    public ObjectAbilMoveJump(ObjectConfig config, float cooldown, float wait, int uses, float duration): base(config, cooldown, wait, uses, duration){
        _name = "jump";
    }


    protected override void _act_move(KeyPos input) { 
        // _act_force(new(0, input.y_dir * _Config._move_force.y), true);
        _act_force(new(0, input.y * _Config._move_force.y), true);
    }
}
