using System.Collections;
using System.Collections.Generic;
using System;
using System.Threading;
using UnityEngine;
using UnityEngine.Tilemaps;
using Cysharp.Threading.Tasks;
using Unity.VisualScripting;


public class ObjectAbilMoveBase{
    // ---------- Config ----------
    public ObjectConfig _Config;
    // ---------- Init ----------
    public string _name;
    public bool _moving;
    public bool _waiting;
    public bool _cooldowning;
    public float _wait;
    protected float _cooldown;
    protected int _uses_init;
    // ---------- Status ----------
    public int _uses;
    public float _duration;

    public ObjectAbilMoveBase(ObjectConfig config, float cooldown, float wait, int uses, float duration){
        // ---------- Config ----------
        _Config = config;
        // ---------- Init ----------
        _wait = wait;
        _cooldown = cooldown;
        _uses_init = uses;
        _duration = duration;
        _reset();
    }

    protected virtual bool _check(KeyPos input) { return true; }
    protected virtual void _act_move(KeyPos input) { }
    protected virtual void _act_done() { }
    protected virtual void _set_moving_status(bool isStart) { }

    // ---------- Action ----------
    public bool _act(KeyPos input){
        if (check() && _check(input)){
            init().Forget();
            _act_move(input);
            act_done();
            _act_done();
            return true;
        }
        return false;
    }

    public async UniTaskVoid _act_wait(float time){
        _waiting = true;
        await UniTask.Delay(TimeSpan.FromSeconds(time));
        _waiting = false;
    }

    bool check() { 
        if (_waiting) return false;
        if (_cooldowning && !_moving) return false;
        if (_uses == 0) return false;
        return true; 
    }

    void act_done() { 
        if (_uses > 0) _uses--;
    }

    async UniTaskVoid init(){
        _moving = true;
        _set_moving_status(true);
        if (_duration < 0) return;
        if (_duration > 0) await UniTask.Delay(TimeSpan.FromSeconds(_duration));
        _moving = false;
        _set_moving_status(false);
        if (_cooldown <= 0) return;
        _cooldowning = true;
        await UniTask.Delay(TimeSpan.FromSeconds(_cooldown));
        _cooldowning = false;
    }

    // ---------- Status ----------
    public void _reset() {
        _uses = _uses_init;
        _waiting = false;
        _cooldowning = false;
    }

    // ---------- Base ----------
    protected void _act_force(Vector2 force, bool isInstant=false){
        if (!isInstant) { // such as player move
            Vector2 final_speed = new() {
                x = restrict_value_by_ori_max_change(_Config._rb.velocity.x, _Config._max_move_speed.x, force.x),
                y = restrict_value_by_ori_max_change(_Config._rb.velocity.y, _Config._max_move_speed.y, force.y)
            };
            Vector2 final_force = new(){
                x = (final_speed.x - _Config._rb.velocity.x) * _Config._rb.mass / Time.fixedDeltaTime,
                y = (final_speed.y - _Config._rb.velocity.y) * _Config._rb.mass / Time.fixedDeltaTime
            };
            _Config._rb.AddForce(final_force, ForceMode2D.Force);
        } else {// such as player jump or be blown up
            _Config._rb.AddForce(force, ForceMode2D.Impulse);
        }
    }

    float restrict_value_by_ori_max_change(float v_ori, float v_max, float v_ch){
        if (Mathf.Abs(v_ori + v_ch) <= v_max) return v_ori + v_ch;
        int dir_ori = v_ori > 0 ? 1 : -1;
        if (v_ori * dir_ori > v_max) return (v_ch * dir_ori >= 0) ? v_ori : v_ori + v_ch / 10;
        else return dir_ori * v_max;
    }
}
