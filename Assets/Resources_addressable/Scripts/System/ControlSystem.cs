using Cinemachine;
using UnityEngine;


public class ControlSystem{
    SystemManager sys;
    // public GameObject _player;
    public ObjectConfig _player;

    public ControlSystem(SystemManager sys){
        this.sys = sys;
        // _HierSearch = GameObject.Find("System").GetComponent<SystemManager>();
        // _HierSearch._CtrlSys = this;
    }

    
    public void _set_player(ObjectConfig player){
        _player = player;
        sys._searchInit<CinemachineVirtualCamera>("Camera", "Player Camera").Follow = _player._self.transform;
    }
}
