/**
 * Created by 齐山 on 16/9/26.
 */

'use strict'

const view = {

  // ref: ref of the web component.
  focus: function (ref) {
    const comp = this.getComponentManager().getComponent(ref)
    comp.node.focus()
  },
  blur: function (ref) {
    const comp = this.getComponentManager().getComponent(ref)
    comp.node.blur()
  }

}

const meta = {
  view: [{
    name: 'focus',
    args: ['string']
  },{
    name: 'blur',
    args: ['string']
  }
  ]
}

export default {
  init: function (Weex) {
    Weex.registerApiModule('view', view, meta)
  }
}
