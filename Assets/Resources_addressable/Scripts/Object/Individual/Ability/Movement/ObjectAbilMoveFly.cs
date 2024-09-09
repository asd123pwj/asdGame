using System.Collections;
using System.Collections.Generic;
using System;
using System.Threading;
using UnityEngine;
using UnityEngine.Tilemaps;
using Cysharp.Threading.Tasks;
using Unity.VisualScripting;

public class ObjectAbilMoveFly: ObjectAbilMoveBase{
    public ObjectAbilMoveFly(ObjectConfig config, float cooldown, float wait, int uses): this(config, cooldown, wait, uses, -1){}
    public ObjectAbilMoveFly(ObjectConfig config, float cooldown, float wait, float duration): this(config, cooldown, wait, -1, duration){}
    public ObjectAbilMoveFly(ObjectConfig config, float cooldown, float wait, int uses, float duration): base(config, cooldown, wait, uses, duration){
        _name = "fly";
    }

    protected override void _act_move(KeyPos input) { 
        _act_force(new(input.x * _Config._move_force.x, input.y * _Config._move_force.y));
    }

    protected override void _set_moving_status(bool isStart) {
        _Config._AttrMoveFloat._act_float(isStart);
    }
}
