class Plot {
  static macro function plot(e):Void;

  public static function start():Void {
    var globalSpeed = 0.03;
    var solvedMusic = [];
    var platformUp = false;
    var kingSequence = [0, 0, 4, 2, 1, 1, 3, 4, 2, 3, 0, 0];
    var kingSlayer = false;
    var kingKnown = false;
    var roseKnown = false;
    var roseOpen = false;
    plot({
      function collectTape(tape:Vis, parent:Vis, n:Int, wakeup:Void->Void):Void {
        !{
          ani(tape.y += 10, 0.5);
          parent.sub.remove(tape);
          tape.globalise();
          tape.deglobalise(R.effectVis);
          R.effectVis.add(tape);
          Sfx.play("SFX_Fanfare", 0);
          ani(
            tape.x = 0,
            tape.y = 0,
            tape.angle = AO,
            tape.scale = 1,
            tape.zBias = 100.,
            1.
          );
          ani(
            tape.angle += AF,
            tape.scale = 1.5,
            2.
          );
          ani(
            tape.angle += AF - AO,
            tape.scale = 0.5,
            3.
          );
          ani(
            tape.x = -300,
            tape.scale = 0.3,
            2.
          );
          R.deck.collect(n);
          wakeup();
        };
      }
      function fourBeta(wakeup:Void->Void):Void {
        var betaRepeats = 0;
        R.musicPuzzle.betaWakeup = () -> {
          if (R.cameraTarget == VM["1c/rose"] && betaRepeats++ >= 3) {
            R.deck.stopAll();
            R.musicPuzzle.betaWakeup = null;
            wakeup();
          }
        };
      }
      function musicPuzzle(n:Int, door:Vis, wakeup:Void->Void):Void {
        !{
          if (solvedMusic.indexOf(n) == -1) {
            R.deck.stopAll();
            door.zoom(4.5);
            door.zoomOZ = -3;
            door.sub[0].alpha.t(1);
            beat;
            R.musicPuzzle.show = true;
            R.cancelText = R.deck.inventory.length > 0 ? "Match the melody" : "Go back";
            R.cancelWakeup = () -> {
              R.unzoom();
              door.sub[0].alpha.t(0);
              R.musicPuzzle.show = false;
              R.musicPuzzle.solveWakeup = null;
            };
            wait(R.musicPuzzle.prepare(n));
            solvedMusic.push(n);
            R.cancelWakeup = null;
            R.deck.stopAll();
            beat;
            Sfx.play("SFX_Success", 0);
            R.musicPuzzle.show = false;
            R.musicPuzzle.solveWakeup = null;
            beat;
            R.unzoom();
            door.sub[0].alpha.t(0);
          }
          beat;
          wakeup();
        };
      }
      // floor 1
      room("1a", {
        _.plaque1.rename("Plaque").voiced(0xc4a7bd);
        _.plaque2.rename("Plaque (tape decks)").voiced(0xc4a7bd);
        _.plaque2.active = false;
        _.tapeholder.rename("Tape");
        _.face.rename("Creepy face", true).voiced(0x8e9a7b);
        _.door1.rename("Door");
        var readPlaque1 = false;
        var readPlaque2 = false;
        var annoying = false;
        var faceProg = 0;
        var faceSong1 = 0;
        var faceSong2 = 0;
        var faceSong3 = 0;
      }, {
        nth(!{
          player("Where am I?");
          player("How did I get here?");
          Sfx.play("SFX_Mumble_2"); _.face.say("Welcome to the");
          Sfx.play("SFX_Mumble_4"); _.face.say("$s$bc a s s e t t l e$s$b");
          beat;
          player("Castle?");
          Sfx.play("SFX_Mumble_4"); _.face.say("$s$bc a s s e t t l e !$s$b");
          _.face.updateCylinderHalf("face1blink", 7, "face1inside");
          Sfx.play("SFX_COUGH_ECHO_ECHO_ECHO");
          beat;
          _.face.updateCylinderHalf("face1", 7, "face1inside");
          _.face_cp2.alpha.t(0.5);
          Sfx.play("SFX_Mumble_3"); _.face.say("Like a castle but...");
          _.face_cp2.alpha.t(1);
          Sfx.play("SFX_Mumble_8"); _.face.say("more cassette.");
          player("Oh...");
        }, {});
        if (kingSlayer) !{
          Sfx.play("SFX_COUGH_ECHO_ECHO_ECHO");
          beat;
          R.beatWait = true;
          _.face_cp3.zoom();
          _.face.updateCylinderHalf("face1blink", 7, "face1inside");
          Sfx.play("SFX_Mumble_4"); _.face.say("So you have figured it out...");
          ani(_.face_cp0.alpha.target = 0, 1);
          Sfx.play("SFX_DeepMumble_1"); _.face.say("Not so democratic after all...");
          ani(_.face_cp1.alpha.target = 0, 1);
          ani(_.face_cp2.alpha.target = 0, 1);
          _.face.say("I hope you know what you are doing...");
          ani(_.face_cp3.alpha.target = 0, 1);
          Sfx.play("SFX_Mumble_4"); _.face.say("Because the one below is ruthless...");
          ani(_.face_cp4.alpha.target = 0, 1);
          ani(_.face_cp5.alpha.target = 0, 1);
          ani(_.face_cp6.alpha.target = 0, 1);
          _.face.obstructs = false;
          _.face.active = false;
          r.updatePaths();
          R.unzoom();
          beat;
          beat;
          R.beatWait = true;
          wait(r.walkTo(81, 5));
          beat;
          R.beatWait = true;
          R.player.sub[0].alpha.t(0);
          R.player.sub[1].alpha.t(0);
          R.player.sub[2].alpha.t(0);
          R.ending(2, "you slayed the king");
        }
        _.plaque1.interact(!{
          nth({
            player("There's a plaque on the wall here.");
            player("It says ...");
          }, {});
          _.plaque1.say("\"$bClick$b on things to interact with them.\"");
          _.plaque1.say("\"$bHold$b the mouse button at screen edges to turn the camera around.\"");
          _.plaque1.say("\"You can also use the $barrow keys$b and $bW A S D$b.\"");
          readPlaque1 = true;
          _.plaque1.rename("Plaque (controls)");
        });
        _.plaque2.interact(!{
          nth({
            if (readPlaque1) {
              player("Another plaque.");
            } else {
              player("There's a plaque on the wall here.");
            }
            player("It says ...");
          }, {});
          _.plaque2.say("\"$bDrag and drop$b tapes into your tape decks.\"");
          _.plaque2.say("\"Use the $bbuttons$b to rewind, play, pause, fast forward, or eject the tape.\"");
        });
        _.tapeholder.interact(!{
          nth({
            _.plaque2.active = true;
            wait(collectTape(_.tape1, _.tapeholder, 0));
            _.plaque2.zoom();
            ani(_.plaque2.alpha.target = 1, 1);
            player("A plaque just appeared!");
            player("It says ...");
            _.plaque2.say("\"$bDrag and drop$b tapes into your tape decks.\"");
            _.plaque2.say("\"Use the $bbuttons$b to rewind, play, pause, fast forward, or eject the tape.\"");
            _.tapeholder.updateWall("tapeholdclosed");
          }, {
            player("It is empty now.");
          });
        });
        _.face.interact(!{
          random({
            faceSong1 = 1;
          _.face.updateCylinderHalf("face1talk", 7, "face1inside");
            Sfx.play("SFX_DeepMumble_1"); _.face.say("$m... still pyre smoldering ...");
          _.face.updateCylinderHalf("face1", 7, "face1inside");
          }, {
            faceSong2 = 1;
          _.face.updateCylinderHalf("face1talk", 7, "face1inside");
            Sfx.play("SFX_DeepMumble_2"); _.face.say("$m... the rolling waves in labyrinths of coral caves ...");
          _.face.updateCylinderHalf("face1", 7, "face1inside");
          }, {
            faceSong3 = 1;
          _.face.updateCylinderHalf("face1talk", 7, "face1inside");
            Sfx.play("SFX_DeepMumble_3"); _.face.say("$m... the weaver in the web that he made ...");
          _.face.updateCylinderHalf("face1", 7, "face1inside");
          });
          _.face.say("What?");
          while (true) choice(
            if (annoying) "You're a bit annoying, you know." => {
              _.face.updateCylinderHalf("face1blink", 7, "face1inside");
              Sfx.play("SFX_COUGH_ECHO_ECHO_ECHO_2");
              R.beatWait = true;
              ani(_.face_cp0.alpha.target = 0                             , 1);
              ani(_.face_cp1.alpha.target = 0, _.face_cp0.alpha.target = 1, 1);
              ani(_.face_cp2.alpha.target = 0, _.face_cp1.alpha.target = 1, 1);
              ani(_.face_cp3.alpha.target = 0, _.face_cp2.alpha.target = 1, 1);
              ani(_.face_cp4.alpha.target = 0, _.face_cp3.alpha.target = 1, 1);
              ani(_.face_cp5.alpha.target = 0, _.face_cp4.alpha.target = 1, 1);
              ani(_.face_cp6.alpha.target = 0, _.face_cp5.alpha.target = 1, 1);
              ani(                             _.face_cp6.alpha.target = 1, 1);
              R.beatWait = false;
              _.face.updateCylinderHalf("face1", 7, "face1inside");
              Sfx.play("SFX_Mumble_7"); _.face.say("Aren't we all.");
              annoying = false;
            },
            if (faceProg == 0) "What is this place?" => {
              Sfx.play("SFX_Mumble_5"); _.face.say("Weren't you listening?");
              Sfx.play("SFX_Mumble_2"); _.face.say("It is the");
              Sfx.play("SFX_Mumble_4"); _.face.say("$s$bc a s s e t t l e !$s$b");
              player("How do you shake your voice like that?");
              Sfx.play("SFX_Mumble_3"); _.face.say("Practice.");
              faceProg++;
            },
            if (faceProg == 1) "But really, what $bis$b this place?" => {
              Sfx.play("SFX_Mumble_1"); _.face.say("It is a place you may never leave.");
              Sfx.play("SFX_Mumble_6"); _.face.say("Solve all the puzzles you want ...");
              Sfx.play("SFX_Mumble_4"); _.face.say("The $s$bc a s s e t t l e !$s$b keeps its subjects.");
              beat;
              player("Who is the king of this castle?");
              Sfx.play("SFX_Mumble_7"); _.face.say("Aren't we all.");
              player("We are all kings?");
              Sfx.play("SFX_Mumble_2"); _.face.say("It's very democratic.");
              faceProg++;
            },
            if (faceProg == 2) "Don't you want to leave?" => {
              Sfx.play("SFX_Mumble_3"); _.face.say("It might surprise you, but ...");
              Sfx.play("SFX_Mumble_6"); _.face.say("The world outside isn't really for me.");
              player("Why is that?");
              Sfx.play("SFX_Mumble_7"); _.face.say("I think being a grotesque face in a wall, I am perfectly suited to this place.");
            },
            if (faceSong1 + faceSong2 + faceSong3 == 3) "What are those songs you sing?" => {
              Sfx.play("SFX_Mumble_8"); _.face.say("Just memories of a different age.");
            },
            if (kingKnown) "You are the king of this castle." => {
              _.face.updateCylinderHalf("face1blink", 7, "face1inside");
              beat;
              _.face.updateCylinderHalf("face1", 7, "face1inside");
              beat;
              Sfx.play("SFX_Mumble_4"); _.face.say("So you have figured it out...");
              _.face.say("Whispers in the dark can be dangerous.");
              _.face.say("Knowledge is dangerous.");
              _.face_cp2.alpha.t(0.5);
              _.face.say("Perhaps we can make a deal.");
              _.face_cp2.alpha.t(1);
              _.face.say("I'll let you live, and you forget about this.");
              choice(
                "No." => {
                  beat;
                  beat;
                  _.face.updateCylinderHalf("face1blink", 7, "face1inside");
                  R.beatWait = true;
                  Sfx.play("SFX_COUGH_ECHO_ECHO_ECHO_2");
                  beat;
                  beat;
                  beat;
                  R.beatWait = true;
                  Sfx.play("SFX_Mechanism_5");
                  _.face_cp3.zoom();
                  beat;
                  beat;
                  _.face.updateCylinderHalf("face1", 7, "face1inside");
                  beat;
                  beat;
                  var reg = getReg("face1inside");
                  var pw:Int = Std.int(reg.tw / 7);
                  Sfx.play("SFX_Mechanism_2").fadeIn(100); _.face.sub[0].tex(reg.tx + 0 * pw, reg.ty, pw, reg.th);
                  beat;
                  Sfx.play("SFX_Mechanism_1").fadeIn(100); _.face.sub[1].tex(reg.tx + 1 * pw, reg.ty, pw, reg.th);
                  beat;
                  Sfx.play("SFX_Mechanism_2").fadeIn(100); _.face.sub[2].tex(reg.tx + 2 * pw, reg.ty, pw, reg.th);
                  beat;
                  Sfx.play("SFX_Mechanism_1").fadeIn(100); _.face.sub[3].tex(reg.tx + 3 * pw, reg.ty, pw, reg.th);
                  beat;
                  Sfx.play("SFX_Mechanism_2").fadeIn(100); _.face.sub[4].tex(reg.tx + 4 * pw, reg.ty, pw, reg.th);
                  beat;
                  Sfx.play("SFX_Mechanism_1").fadeIn(100); _.face.sub[5].tex(reg.tx + 5 * pw, reg.ty, pw, reg.th);
                  beat;
                  Sfx.play("SFX_Mechanism_2").fadeIn(100); _.face.sub[6].tex(reg.tx + 6 * pw, reg.ty, pw, reg.th);
                  beat;
                  beat;
                  R.unzoom();
                  R.player.zoomOZ = 200.;
                  R.cameraZ.value = 200.;
                  beat;
                  R.ending(1, "you did not choose correctly");
                  terminate();
                },
                "Very well." => {
                  R.gameOver = true;
                  ani(
                    R.player.zoomOZ = 200.,
                    4.
                  );
                  Sfx.play("SFX_Mumble_4");
                  beat;
                  beat;
                  beat;
                  Sfx.play("SFX_Cassette_1");
                  beat;
                  beat;
                  Sfx.play("SFX_Cassette_4");
                  beat;
                  beat;
                  beat;
                  R.reset();
                  terminate();
                }
              );
            },
            "Bye." => break
          );
        });
        _.door1.interact(!{
          nth({
            _.door1.zoom();
            player("A door!");
            player("Could be an exit...");
            Sfx.play("SFX_Mumble_8"); _.face.say("Don't bet on it.");
            _.face.rename("Annoying face", true);
            annoying = true;
            _.door1.sub[0].alpha.t(1);
            player("There's an inscription here...");
            R.unzoom();
          }, {});
          wait(musicPuzzle(0, _.door1));
          enter("1b", 32, 16);
          nth({
            player("It reacted to my music!");
            player("This must be the key to this place...");
          }, {});
          _.door1.rename("Door (to the Noon room)");
        });
      });
      room("1b", {
        _.door1.rename("Door");
        _.trapdoor.rename("Trapdoor");
      }, {
        _.door1.interact(!{
          nth({
            _.door1.zoom();
            player("Another door...");
            _.door1.sub[0].alpha.t(1);
            player("The inscription is different.");
            R.unzoom();
          }, {});
          wait(musicPuzzle(4, _.door1));
          enter("1c", 16, 32);
          _.door1.rename("Door (to the Dusk room)");
        });
        _.trapdoor.interact(!{
          nth({
            _.trapdoor.zoom(3.5);
            player("It's a trapdoor.");
          }, {});
          player("It won't budge.");
          player("The symbol is just like the one for the doors...");
        });
      });
      room("1c", {
        _.door1.rename("Door");
        _.plaque1.rename("Plaque").voiced(0xc4a7bd);
        _.rose_front.rename("Rose emblem");
        _.rose_puzzle.rename("Weights");
        _.rose_puzzle_0.rename("Position 0");
        _.rose_puzzle_1.rename("Position 1");
        _.rose_puzzle_2.rename("Position 2");
        _.rose_puzzle_3.rename("Position 3");
        _.rose_puzzle_4.rename("Position 4");
        _.tapeholder.rename("Tape");
        var picked = -1;
        var spring = [1, 3, 2, 5, 4];
        var weight = [5, 4, 3, 2, 1];
        var dummy = 0.;
        var targets:Array<Float> = [0, 0, 0, 0, 0];
        var rebalance:Void->Void = null;
        var roseSolved = false;
        var roseWasSolved = false;
        var doubleHistory = [];
        function click(n:Int):Void {
          if (picked == -1) {
            R.cancelText = "Choose another weight to swap";
            R.cancelWakeup = () -> click(n);
            picked = n;
            Sfx.play("SFX_Spring_Pull");
          } else {
            Sfx.play("SFX_Spring_LetGo_Short");
            if (picked != n) {
              doubleHistory.resize(0);
              var w1 = VM['1c/rose/puzzle/$picked'].sub[1];
              var w2 = VM['1c/rose/puzzle/$n'].sub[1];
              VM['1c/rose/puzzle/$picked'].sub.remove(w1);
              VM['1c/rose/puzzle/$n'].sub.remove(w2);
              VM['1c/rose/puzzle/$picked'].sub.push(w2);
              VM['1c/rose/puzzle/$n'].sub.push(w1);
              var tmp = weight[n];
              weight[n] = weight[picked];
              weight[picked] = tmp;
              rebalance();
            } else if (!kingSlayer) {
              doubleHistory.push(n);
              if (doubleHistory.length > kingSequence.length) doubleHistory.shift();
              if (doubleHistory.join("") == kingSequence.join("")) {
                // !!!
                kingSlayer = true;
                Sfx.play("SFX_COUGH_ECHO_ECHO_ECHO", 0);
              }
            }
            R.cancelWakeup = null;
            picked = -1;
          }
        }
      }, {
        rebalance = () -> !{
          dummy = 0.;
          for (i in 0...5) {
            targets[i] = -.5 + (spring[i] < weight[i] ? -3.5 : (spring[i] > weight[i] ? 3.5 : 0));
          }
          _.rose_puzzle_0.rename("Position 0");
          _.rose_puzzle_1.rename("Position 1");
          _.rose_puzzle_2.rename("Position 2");
          _.rose_puzzle_3.rename("Position 3");
          _.rose_puzzle_4.rename("Position 4");
          ani(
            _.rose_puzzle_0.z = targets[0],
            _.rose_puzzle_1.z = targets[1],
            _.rose_puzzle_2.z = targets[2],
            _.rose_puzzle_3.z = targets[3],
            _.rose_puzzle_4.z = targets[4],
            1.
          );
          roseSolved = true;
          for (i in 0...5) if (spring[i] != weight[i]) roseSolved = false;
          if (roseSolved) {
            roseWasSolved = true;
            nth({
              player("I think that's how it should look.");
            }, {});
            if (!platformUp) {
              platformUp = true;
              VM["1d/platform"].zoom(1.2, -AQ);
              var s = Sfx.play("SFX_Mechanism_5", 0);
              ani(
                VM["1d/platform"].light.target = 1,
                VM["1d/platform"].z = -22,
                7.
              );
              s.fadeOut(1000);
              VM["1d/platform"].obstructs = false;
              R.castle.roomMap["1d"].updatePaths();
              R.unzoom();
            }
            nth({
              VM["1d/platform"].light.t(0.5);
              player("I heard a noise from the next room ...");
            }, {});
          } else if (roseWasSolved) {
            nth({
              player("Now it's unsolved again.");
            }, {});
            if (platformUp) {
              platformUp = false;
              VM["1d/platform"].zoom(1.2, -AQ);
              var s = Sfx.play("SFX_Mechanism_6", 0);
              ani(
                VM["1d/platform"].light.target = 0.5,
                VM["1d/platform"].z = -22 - 24,
                4.
              );
              s.fadeOut(800);
              VM["1d/platform"].obstructs = true;
              R.castle.roomMap["1d"].updatePaths();
              R.unzoom();
            }
          }
        };
        _.rose_front.interact(!{
          if (!roseOpen) {
            _.rose.zoom(2);
            nth({
              player("Hm, it looks like a rose?");
            }, {
              if (!roseKnown) {
                player("Maybe I should look for a hint elsewhere.");
              }
            });
            R.deck.stopAll();
            wait(fourBeta());
            // puzzle
            Sfx.play("SFX_Mechanism_1");
            r.walkTo(49, 31);
            ani(_.rose.y += 3, .1);
            beat;
            _.rose_puzzle.active = true;
            var s = Sfx.play("SFX_Mechanism_4", 0);
            ani(_.rose.angle += AH, 4.);
            s.fadeOut(500);
            Sfx.play("SFX_Mechanism_2");
            ani(_.rose.y -= 3, .25);
            _.rose_puzzle.ix = _.rose_front.deix();
            R.unzoom();
            roseOpen = true;
            player("That worked!");
          }
          _.rose_puzzle_wall.zoom(1.8);
          R.deck.open = false;
          rebalance();
        });
        _.rose_puzzle_0.interact(click(0)).detailed(1);
        _.rose_puzzle_1.interact(click(1)).detailed(1);
        _.rose_puzzle_2.interact(click(2)).detailed(1);
        _.rose_puzzle_3.interact(click(3)).detailed(1);
        _.rose_puzzle_4.interact(click(4)).detailed(1);
        _.door1.interact(!{
          wait(musicPuzzle(5, _.door1));
          enter("1d", 32, 112);
          _.door1.rename("Door (to the Night room)");
        });
        _.tapeholder.interact(!{
          nth({
            wait(collectTape(_.tape2, _.tapeholder, 1));
            _.tapeholder.updateWall("tapeholdclosed");
          }, {
            player("It is empty now.");
          });
        });
        _.plaque1.interact(!{
          nth({
            player("Wallplaque.");
            player("It says ...");
          }, {});
          _.plaque1.say("\"You can $bpress play$b on one tape deck while the other is playing.\"");
          _.plaque1.rename("Plaque (multiple tapes)");
        });
      });
      room("1d", {
        _.door1.rename("Door");
        _.button.rename("Button");
        _.buttons.rename("Buttons");
        _.buttons_b0.rename("Button 1");
        _.buttons_b1.rename("Button 2");
        _.buttons_b2.rename("Button 3");
        _.tapeholder.rename("Tape");
        _.tapeholder.active = false;
        var level = 0;
        var stages = [
          // - | v
          ["cas", "ing", "cad", "cascading"],
          ["ism", "han", "mec", "mechanism"],
          ["tic", "ari", "thme", "arithmetic"],
          ["tned", "ser", "nop", "tnednopser"],
          ["myrh", "eso", "cal", "esomyrhcal"],
          // | - - | | - | - v
          ["ull", "oll", "end", "ollullullollollullollullend"],
        ];
        var history = [];
        var clicked = 0;
        var click:Void->Void = null;
      }, {
        click = () -> !{
          Sfx.play("SFX_Mechanism_1");
          if (level >= stages.length) {
            beat;
            terminate();
          }
          var cur:String = stages[level][clicked];
          VM['1d/buttons/b$clicked'].say(cur);
          history.push(cur);
          if (history.length > (level < 5 ? 3 : 9)) history.shift();
          if (history.join("") == stages[level][3]) {
            _.buttons_b1.say("$m" + history.join(""));
            history.resize(0);
            level++;
            if (level == 3) {
              roseKnown = true;
              Sfx.play("SFX_DeepMumble_2"); _.buttons_b1.say("it blooms after four betas");
              player("What does? What betas?");
              Sfx.play("SFX_DeepMumble_3"); _.buttons_b1.say("$mit $bbloom$bs after $bfour$b $bbeta$bs$m");
            }
            if (level == 5) {
              R.unzoom();
              _.tapeholder.active = true;
              _.tapeholder.alpha.t(1);
              player("One more tape for the collection!");
            };
            if (level == 6) {
              R.unzoom();
              beat;
              Sfx.play("SFX_DeepMumble_2"); _.buttons_b1.say("the king hates a state of passivity");
              Sfx.play("SFX_DeepMumble_3"); _.buttons_b1.say("one taken, one replaced, yet no different");
              kingKnown = true;
              VM["1a/face"].rename("The King", true);
              Sfx.play("SFX_Mechanism_5").pos(-5, 0, 0).fadeIn(4000);
              Sfx.play("SFX_Mechanism_6").pos(5, 0, 0).fadeIn(4000);
              _.buttons_b0.say("$b$m0$m$b");
              _.buttons_b1.say("$b$m0$m$b");
              _.buttons_b2.say("$b$m4$m$b");
              _.buttons_b0.say("$b$m2$m$b");
              _.buttons_b1.say("$b$m1$m$b");
              _.buttons_b2.say("$b$m1$m$b");
              _.buttons_b0.say("$b$m3$m$b");
              _.buttons_b1.say("$b$m4$m$b");
              _.buttons_b2.say("$b$m2$m$b");
              _.buttons_b0.say("$b$m3$m$b");
              _.buttons_b1.say("$b$m0$m$b");
              _.buttons_b2.say("$b$m0$m$b");
            }
          }
        };
        _.button.interact(!{
          if (platformUp) {
            wait(r.walkTo(45, 8));
            nth({
              player("Let's see what this does...");
            }, {});
            beat;
            Sfx.play("SFX_Mechanism_1");
            beat;
            R.beatWait = true;
            r.walkTo(41, 16);
            var s = Sfx.play("SFX_Mechanism_6", 0);
            ani(
              VM["1d/platform"].light.target = 0.0,
              R.player.light.target = 0.0,
              VM["1d/platform"].z = -22 - 240,
              R.player.z -= 240,
              10.
            );
            s.fadeOut(3800);
            Sfx.play("SFX_COUGH_ECHO_ECHO_ECHO_2").pos(-2, 0, 0);
            ani(
              R.player.zoomOZ = -220.,
              5.
            );
            R.ending(4, "you broke out of the loop");
          } else {
            player("I can't reach it.");
          }
        });
        _.buttons.interact(!{
          wait(r.walkTo(45, 80));
          _.buttons_b1.zoom();
          R.deck.open = false;
          nth({
            player("What are these symbols?");
            Sfx.play("SFX_Success"); _.buttons_b1.say("hi");
            player("Huh?");
            beat;
            Sfx.play("SFX_Fail"); _.buttons_b1.say("$bhi$b");
          }, {});
          if (level >= 3 && !roseOpen) {
            Sfx.play("SFX_DeepMumble_3"); _.buttons_b1.say("$mit $bbloom$bs after $bfour$b $bbeta$bs$m");
          }
          if (level >= stages.length && !kingSlayer) {
            Sfx.play("SFX_DeepMumble_2"); _.buttons_b1.say("the king hates a state of passivity");
            Sfx.play("SFX_DeepMumble_3"); _.buttons_b1.say("one taken, one replaced, yet no different");
            Sfx.play("SFX_Mechanism_5").pos(-5, 0, 0).fadeIn(4000);
            Sfx.play("SFX_Mechanism_6").pos(5, 0, 0).fadeIn(4000);
            _.buttons_b0.say("$b$m0$m$b");
            _.buttons_b1.say("$b$m0$m$b");
            _.buttons_b2.say("$b$m4$m$b");
            _.buttons_b0.say("$b$m2$m$b");
            _.buttons_b1.say("$b$m1$m$b");
            _.buttons_b2.say("$b$m1$m$b");
            _.buttons_b0.say("$b$m3$m$b");
            _.buttons_b1.say("$b$m4$m$b");
            _.buttons_b2.say("$b$m2$m$b");
            _.buttons_b0.say("$b$m3$m$b");
            _.buttons_b1.say("$b$m0$m$b");
            _.buttons_b2.say("$b$m0$m$b");
          }
        });
        _.buttons_b0.interact({ clicked = 0; click(); }).detailed(1);
        _.buttons_b1.interact({ clicked = 1; click(); }).detailed(1);
        _.buttons_b2.interact({ clicked = 2; click(); }).detailed(1);
        _.door1.interact(!{
          wait(musicPuzzle(6, _.door1));
          enter("1a", 112, 32);
          _.door1.rename("Door (to the Dawn room)");
          nth({
            player("Back where I started...");
            Sfx.play("SFX_Mumble_1"); VM["1a/face"].say("Did you enjoy the tour?");
            player("There must be a way out of here.");
          }, {});
        });
        _.tapeholder.interact(!{
          nth({
            wait(collectTape(_.tape3, _.tapeholder, 3));
            _.tapeholder.updateWall("tapeholdclosed");
          }, {
            player("It is empty now.");
          });
        });
      });
      // floor 2 ...
      // floor 3 ...
    });
  }
}
