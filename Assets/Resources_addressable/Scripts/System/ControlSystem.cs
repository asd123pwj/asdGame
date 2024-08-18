using Cinemachine;
using UnityEngine;


public class ControlSystem : MonoBehaviour{
    HierarchySearch _HierSearch;
    public GameObject _player;

    void Start(){
        _HierSearch = GameObject.Find("System").GetComponent<HierarchySearch>();
        _HierSearch._CtrlSys = this;
    }

    void Update(){
        
    }
    
    public void _set_player(GameObject player){
        _player = player;
        _HierSearch._searchInit<CinemachineVirtualCamera>("Camera", "Player Camera").Follow = _player.transform;
    }
}
