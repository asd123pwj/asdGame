using System.Collections.Generic;
using UnityEngine;

public class ObjectContactCheckGround: ObjectContactBase{
    public List<int> groundList = new();
    public ObjectContactCheckGround(ObjectBase Base): base(Base){
        _Base.status[GetType().Name] = false;
    }

    public override void OnCollisionEnter2D(Collision2D col){
        for(int i = 0; i < col.contactCount; i++){
            ContactPoint2D contact = col.GetContact(i);
            if (contact.normal.y > 0){
                groundList.Add(col.gameObject.GetInstanceID());
                _Base.status[GetType().Name] = true;
                break;
            }
        }
    }
    public override void OnCollisionExit2D(Collision2D col){
        groundList.Remove(col.gameObject.GetInstanceID());
        if (groundList.Count == 0){
            _Base.status[GetType().Name] = false;
        }
    }
}