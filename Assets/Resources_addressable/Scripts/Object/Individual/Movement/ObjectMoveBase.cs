using System;
using Cysharp.Threading.Tasks;


public class ObjectMoveBase{
    // ---------- Config ----------
    public ObjectBase _Base;
    public float _wait = 0;
    public float _cooldown = 0;
    public int _uses_init = -1;
    public float _duration = 0;
    // ---------- Status ----------
    int _uses;
    bool _moving;
    static bool _waiting;
    bool _cooldowning;

    // public ObjectMoveBase(ObjectBase Base, float cooldown, float wait, int uses, float duration){
    //     // ---------- Config ----------
    //     _Base = Base;
    //     // ---------- Init ----------
    //     _wait = wait;
    //     _cooldown = cooldown;
    //     _uses_init = uses;
    //     _duration = duration;
    //     _reset();
    // }
    public ObjectMoveBase(ObjectBase Base){
        // ---------- Config ----------
        _Base = Base;
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
            _act_wait().Forget();
            return true;
        }
        return false;
    }

    public async UniTaskVoid _act_wait(){
        if (_wait <= 0) return;
        _waiting = true;
        await UniTask.Delay(TimeSpan.FromSeconds(_wait));
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
}
