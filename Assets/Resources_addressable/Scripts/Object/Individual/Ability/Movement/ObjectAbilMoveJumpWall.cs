using System.Collections;
using System.Collections.Generic;
using System;
using System.Threading;
using UnityEngine;
using UnityEngine.Tilemaps;
using Cysharp.Threading.Tasks;
using Unity.VisualScripting;

public class ObjectAbilMoveJumpWall: ObjectAbilMoveBase{
    public ObjectAbilMoveJumpWall(ObjectBase config, float cooldown, float wait, int uses): this(config, cooldown, wait, uses, -1){}
    public ObjectAbilMoveJumpWall(ObjectBase config, float cooldown, float wait, float duration): this(config, cooldown, wait, -1, duration){}
    public ObjectAbilMoveJumpWall(ObjectBase config, float cooldown, float wait, int uses, float duration): base(config, cooldown, wait, uses, duration){
        _name = "jump wall";
    }

    protected override bool _check(KeyPos input) { 
        // if (!_Config._StatusContact._onWall) return false;
        return true; 
    }

    protected override void _act_move(KeyPos input) { 
        // _act_force(new(- input.x_dir * _Config._move_force.x, input.y_dir * _Config._move_force.y), true);
        _act_force(new(- input.x * _Config._move_force.x, input.y * _Config._move_force.y), true);
    }
}
