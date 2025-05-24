using UnityEngine;

public class ObjectContactBase{
    public ObjectBase _Base;
    public ObjectContactBase(ObjectBase Base){
        _Base = Base;
    }

    public virtual void OnCollisionEnter2D(Collision2D col){}
    public virtual void OnCollisionExit2D(Collision2D col){}
    public virtual void OnCollisionStay2D(Collision2D col){}

    public virtual void OnTriggerEnter2D(Collider2D col){}
    public virtual void OnTriggerExit2D(Collider2D col){}
    public virtual void OnTriggerStay2D(Collider2D col){}
}