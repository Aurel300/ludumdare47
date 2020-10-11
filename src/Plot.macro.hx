import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;

class Plot {
  static function plot(e:Expr):Expr {
    var prelude = [];
    var varCtr = 0;
    function walk(e:Expr):Expr {
      return (switch (e.expr) {
        case ECall({expr: EConst(CIdent("nth"))}, args):
          if (args.length < 1) Context.fatalError("at least one argument required for nth", e.pos);
          var state = '_nth_${varCtr++}';
          prelude.push({
            expr: EVars([{name: state, expr: macro -1}]),
            pos: e.pos,
          });
          var res = walk(args.pop());
          for (i in 0...args.length) {
            res = macro if ($i{state} == $v{i}) $e{walk(args[i])} else $res;
          }
          macro {
            $i{state}++;
            $res;
          };
        case ECall({expr: EConst(CIdent("random"))}, args):
          if (args.length < 1) Context.fatalError("at least one argument required for random", e.pos);
          var choices = args.length;
          var res = walk(args.pop());
          for (i in 0...args.length) {
            res = macro if (_rnd == $v{i}) $e{walk(args[i])} else $res;
          }
          macro {
            var _rnd = Std.random($v{choices});
            $res;
          };
        case ECall({expr: EConst(CIdent("choice"))}, args):
          var ret = [];
          ret.push(macro R.choices = []);
          var retAfter = [];
          for (i in 0...args.length) {
            var a = args[i];
            switch (a.expr) {
              case EIf(cond, {expr: EBinop(OpArrow, msg, act)}, null):
                ret.push(macro if ($cond) R.choices.push({
                  msg: $msg,
                  choice: $v{i},
                }));
                retAfter.push(macro if (_chosen == $v{i}) $e{walk(act)});
              case EBinop(OpArrow, msg, act):
                ret.push(macro R.choices.push({
                  msg: $msg,
                  choice: $v{i},
                }));
                retAfter.push(macro if (_chosen == $v{i}) $e{walk(act)});
              case _: Context.fatalError("invalid choice", a.pos);
            }
          }
          ret.push(macro var _chosen:Int = -1);
          ret.push(macro suspend((co, _) -> {
            R.choiceWakeup = (n:Int) -> {
              R.choices = null;
              R.choiceWakeup = null;
              _chosen = n;
              if (co.state != pecan.Co.CoState.Terminated) co.wakeup();
            };
          }));
          ret = ret.concat(retAfter);
          macro $b{ret};
        case ECall({expr: EConst(CIdent("ani"))}, args):
          if (args.length < 1) Context.fatalError("at least one argument required for ani", e.pos);
          var len:Expr = args.pop();
          /*while (args.length > 0) {
            if (!args[args.length - 1].expr.match(EBinop(OpAssignOp(OpAdd | OpSub) | OpAssign, _, _))) {
              if (speed != null) throw "unexpected extra arg";
              speed = args.pop();
              continue;
            }
            break;
          }
          if (speed == null) {
            speed = macro 1.;
          }*/
          var initials = [];
          var progs = [];
          var offA:Expr = null;
          for (i in 0...args.length) {
            var a = walk(args[i]);
            switch (a.expr) {
              case EBinop(OpAssignOp(OpAdd), prop, off):
                offA = off;
                initials.push(prop);
                progs.push(macro $prop = initials[$v{i}] + $off * Hacks.quadInOut(_prog));
              case EBinop(OpAssignOp(OpSub), prop, off):
                offA = off;
                initials.push(prop);
                progs.push(macro $prop = initials[$v{i}] - $off * Hacks.quadInOut(_prog));
              case EBinop(OpAssign, prop, target):
                offA = macro Math.abs($target - $prop);
                initials.push(prop);
                progs.push(macro $prop = initials[$v{i}] + ($target - initials[$v{i}]) * Hacks.quadInOut(_prog));
              case _: throw "unexpected arg";
            }
          }
          macro {
            //var _len:Int = Std.int(Math.ceil(Math.abs($offA) / $speed / globalSpeed));
            var _len:Int = Std.int(Math.ceil($len / globalSpeed));
            var initials:Array<Float> = $a{initials};
            // trace("initials", initials);
            suspend((co, _) -> R.anim.push({
              prog: 0,
              len: _len,
              f: _prog -> $b{progs},
              done: () -> if (co.state == pecan.Co.CoState.Suspended) co.wakeup(),
              blocking: true
            }));
          };
        //case ECall({expr: EConst(CIdent("player"))}, [{expr: EConst(CString(msg))}]):
        case ECall({expr: EConst(CIdent("player"))}, [msg]):
          macro {
            suspend((co, _) -> {
              var _text:Ren.RText = {
                x: 0,
                y: 0,
                msg: Text.split($msg),
                colour: 0x84708f,
                visTarget: R.player,
                prog: 0,
              };
              R.texts.push(_text);
              R.dialogueWakeup = () -> {
                R.dialogueWakeup = null;
                R.texts.remove(_text);
                if (co.state != pecan.Co.CoState.Terminated) co.wakeup();
              };
            });
          };
        case ECall({expr: EField(e, "interact")}, [act]):
          e = walk(e);
          act = walk(act);
          macro $e.ix = Interactible.click(() -> $act);
        case ECall({expr: EConst(CIdent("enter"))}, [room, x, y]):
          room = walk(room);
          x = walk(x);
          y = walk(y);
          macro R.enterRoom($room, $x, $y);
        case ECall({expr: EConst(CIdent("wait"))}, [{expr: ECall(f, args)}]):
          f = walk(f);
          args = args.map(walk);
          args.push(macro () -> if (co.state == pecan.Co.CoState.Suspended) co.wakeup());
          macro {
            suspend((co, _) -> $f($a{args}));
          };
        case ECall({expr: EField(e, "say")}, [msg]):
          e = walk(e);
          macro {
            suspend((co, _) -> {
              var _text:Ren.RText = {
                x: 0,
                y: 0,
                msg: Text.split($msg),
                colour: $e.voiceColour,
                visTarget: $e,
                prog: 0,
              };
              R.texts.push(_text);
              R.dialogueWakeup = () -> {
                R.dialogueWakeup = null;
                R.texts.remove(_text);
                if (co.state != pecan.Co.CoState.Terminated) co.wakeup();
              };
            });
          };
        case EConst(CIdent("beat")):
          macro {
            suspend((co, _) -> {
              R.beatWait = true;
              R.anim.push({
                prog: 0,
                len: 35,
                f: _ -> {},
                done: () -> {
                  R.beatWait = false;
                  if (co.state != pecan.Co.CoState.Terminated) co.wakeup();
                },
                blocking: true,
              });
            });
          };
        case EField({expr: EConst(CIdent("_"))}, obj):
          macro VM[r.id + "/" + $v{obj.split("_").join("/")}];
        //case EField({expr: EField({expr: EConst(CIdent("_"))}, obj1)}, obj2)
        //  if (obj2 != "rename" && obj2 != "interact" && obj2 != "zoom" && obj2 != "active"):
        //  // TODO: this is ugly ...
        //  // trace(obj1, obj2);
        //  macro VM[r.id + "/" + $v{obj1} + "/" + $v{obj2}];
        case EUnop(OpNot, false, e = {expr: EBlock(_)}):
          var state = '_co_${varCtr++}';
          prelude.push({
            expr: EVars([{name: state, expr: pecan.Co.co(walk(e), macro null, macro null)}]),
            pos: e.pos,
          });
          macro $i{state}.run().tick();
        case _: ExprTools.map(e, walk);
      });
    }
    return (switch (e.expr) {
      case EBlock(es):
        {expr: EBlock([ for (e in es) switch (e.expr) {
          case EFunction(kind, f):
            prelude.resize(0);
            varCtr = 0;
            var e = walk(f.expr);
            var ret = [];
            ret = ret.concat(prelude);
            ret.push(e);
            {expr: EFunction(kind, {
              ret: f.ret,
              params: f.params,
              expr: macro $b{ret},
              args: f.args,
            }), pos: e.pos};
          case ECall({expr: EConst(CIdent("room"))}, [name, {expr: EBlock(init)}, update]):
            prelude.resize(0);
            varCtr = 0;
            init = init.map(walk);
            update = walk(update);
            var ret = [];
            ret.push(macro var r = R.castle.roomMap[$name]);
            ret = ret.concat(init);
            ret = ret.concat(prelude);
            ret.push(macro {
              function updateRoom():Void {
                $update;
              }
              r.update = updateRoom;
              // updateRoom();
            });
            var ret = macro $b{ret};
            //Sys.println(new haxe.macro.Printer().printExpr(ret));
            ret;
          case _: Context.fatalError("expected room", e.pos);
        } ]), pos: e.pos};
      case _: Context.fatalError("expected block", e.pos);
    });
  }
}
