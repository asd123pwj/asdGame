using Cysharp.Threading.Tasks;
using UnityEngine;
using System.Reflection;


public class SystemBase{
    // ---------- System Tools ----------
    public static SystemManager _sys;
    public GameConfigs _GCfg { get { return _sys._GCfg; } }
    public ControlSystem _CtrlSys { get { return _sys._CtrlSys; } }
    public InputSystem _InputSys { get { return _sys._InputSys; } }
    public TilemapSystem _TMapSys { get { return _sys._TMapSys; } }
    public ObjectSystem _ObjSys { get { return _sys._ObjSys; } }
    public UISystem _UISys { get { return _sys._UISys; } }
    public MaterialSystem _MatSys { get => _sys._MatSys; }
    public UpdateSystem _UpdateSys { get => _sys._UpdateSys; }
    public CameraManager _CamMgr { get => _sys._CamMgr; }
    // ---------- Config ----------
    public float update_interval = -1;
    // ---------- Status ----------
    public bool _initDone = false;


    public SystemBase(){
        init().Forget();
    }

    public virtual void _update(){
    }

    public virtual bool _check_loaded(){
        return true;
    }

    public virtual void _init(){}
    async UniTaskVoid init(){
        while (true){
            if (!_check_loaded()){
                await UniTask.Delay(100);
                continue;
            }
            register_update();
            _init();
            _initDone = true;
            break;
        }
    }


    void register_update(){
        MethodInfo method = GetType().GetMethod("_update");
        bool is_overridden = method.DeclaringType != typeof(SystemBase);
        _UpdateSys._add_updater(_update, update_interval);
    }
}
