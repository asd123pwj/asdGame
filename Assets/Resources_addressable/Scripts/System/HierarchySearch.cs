using UnityEngine;


public class HierarchySearch : MonoBehaviour{
    // ---------- System Tools ----------
    public ControlSystem _CtrlSys;
    public GameConfigs _GCfg;
    // public HierarchySearch _HierSearch;
    public SaveLoadBase _SL;
    public InputSystem _InputSys;
    public TilemapSystem _TMapSys;
    public ObjectSystem _ObjSys;
    public UISystem _UISys;
    public MaterialSystem _MatSys;
    public UpdateSystem _UpdateSys;
    // ---------- Unity ----------
    public GameObject _input;
    public GameObject _system;
    public GameObject _UI;
    public GameObject _grid;
    public GameObject _object;
    public GameObject _camera;
    void Start(){
        // _input = GameObject.Find("Input");
        // _system = GameObject.Find("System");
        // _canvas = GameObject.Find("Canvas");
        // _grid = GameObject.Find("Grid");
    }

    void Update(){
        
    }

    public T _searchInit<T>(string type){
        if (type == "System") return (T)(object)_system.GetComponent<T>();
        else if (type == "Input") return (T)(object)_input.GetComponent<T>();
        else if (type == "Tilemap") return (T)(object)_grid.GetComponent<T>();
        else if (type == "UI") return (T)(object)_UI.GetComponent<T>();
        else if (type == "Object") return (T)(object)_object.GetComponent<T>();
        else if (type == "Camera") return (T)(object)_camera.GetComponent<T>();
        // else if (type == "Player") return GameObject.FindGameObjectWithTag("Player").GetComponent<T>();
        return default;
    }

    public T _searchInit<T>(string type, string name){
        if (type == "System") return (T)(object)_system.transform.Find(name).GetComponent<T>();
        else if (type == "Input") return (T)(object)_input.transform.Find(name).GetComponent<T>();
        else if (type == "UI") return (T)(object)_UI.transform.Find(name).GetComponent<T>();
        else if (type == "Camera") return (T)(object)_camera.transform.Find(name).GetComponent<T>();
        return default;
    }
}
