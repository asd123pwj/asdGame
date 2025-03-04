using Cysharp.Threading.Tasks;
using UnityEngine;
using System.Reflection;


public class BaseClass{
    // ---------- System Tools ----------
    public static SystemManager _sys;
    public GameConfigs _GCfg => _sys._GCfg; 
    public ControlSystem _CtrlSys => _sys._CtrlSys; 
    public InputSystem _InputSys => _sys._InputSys; 
    public TilemapSystem _TMapSys => _sys._TMapSys; 
    public ObjectSystem _ObjSys => _sys._ObjSys; 
    public UISystem _UISys => _sys._UISys; 
    public MaterialSystem _MatSys => _sys._MatSys; 
    public UpdateSystem _UpdateSys => _sys._UpdateSys; 
    public CameraManager _CamMgr  => _sys._CamMgr; 
    // ---------- Config ----------
    public virtual float _update_interval { get; set; } = 0;
    // public virtual int a  = 1;
    
    // public float _update_interval {get=> update_interval; set { update_interval = value; re_register_update(); } }
    // int update_order = 0;
    // ---------- Status ----------
    public bool _initDone = false;


    public BaseClass(){
        init().Forget();
    }

    public virtual void _update(){}

    public virtual async UniTask _loop(){await UniTask.Delay(0); /* just placeholder */}

    public virtual bool _check_allow_init(){
        return true;
    }

    public virtual void _init(){}
    async UniTaskVoid init(){
        while (true){
            if (!_check_allow_init()){
                await UniTask.Delay(100);
                continue;
            }
            _init();
            register_update();
            run_loop();
            _initDone = true;
            break;
        }
    }

    void register_update(){
        MethodInfo method = GetType().GetMethod("_update");
        bool is_overridden = method.DeclaringType != typeof(BaseClass);
        if (is_overridden){
            _UpdateSys._add_updater(_update, _update_interval);
        }
    }

    // void re_register_update(){
    //     MethodInfo method = GetType().GetMethod("_update");
    //     bool is_overridden = method.DeclaringType != typeof(BaseClass);
    //     if (is_overridden){
    //         _UpdateSys._update_updater(update_order, _update, _update_interval);
    //     }
    // }

    void run_loop(){
        MethodInfo method = GetType().GetMethod("_loop");
        bool is_overridden = method.DeclaringType != typeof(BaseClass);
        if (is_overridden){
            // _loop().Forget();
            // while (true){
                _loop().Forget();
                // await UniTask.DelayFrame(loop_interval);
            // }
        }
    }
}
