# Snake
**Snake game descriptions for automated planning**

The Snake domain is based on the [homonymous game genre](https://en.wikipedia.org/wiki/Snake_(video_game_genre)), in which one or more snakes can either move to clear locations or strike a nearby mice in a grid/graph-based scenario, the mice do not move as they are too afraid.
Each snake occupies one or more adjacent locations due to their long body.
The goal is to hunt all the mice or have the snakes occupying certain locations (which forces them to eat and grow).
Multiple plans may exist in some scenarios due to multiple snakes being able to strike mice in different orderings using different paths.
Plans contain zero or more movement actions and one strike per mouse in the problem instance.
Differently from the game where usually only one mouse is visible at a time, all mice are visible to give more choice, making problems harder.
This domain was motivated by the creative way in which one can describe the snake actions without updating all the snake parts and the little amount of objects required to describe a snake.
It includes [PDDL], [HDDL] and [JSHOP] descriptions and a problem generator.
The HDDL version was one of the [HTN IPC 2020 domains](https://github.com/panda-planner-dev/ipc2020-domains).
You can read more about the HTN IPC planners and domains in the [IPC proceedings](https://gki.informatik.uni-freiburg.de/competition/proceedings.pdf).

## Domain
The domain requires ``:typing``, ``:equality`` and ``:negative-preconditions`` in [PDDL], and also ``:method-preconditions`` and ``:universal-preconditions`` in [HDDL].
The [JSHOP] domain implicitly has the same [HDDL] requirements.
Universal preconditions are used to verify that every location does not contain a mouse and the hunting task is complete.

## Types
All objects are either ``snake`` or ``location``.
This removes the need to have more objects to define each mouse and snake parts.
Removing such objects makes descriptions simpler and grounding faster due to fewer parameters.
Instead of having ``(at ?mouse ?location)`` we can use ``(mouse-at ?location)`` and remove the ``?mouse`` parameter from the ``strike`` action.
If we had opted for snake parts we would have several ways of describing the same long snake, causing an explosion in the state-space.

## Predicates
- ``(occupied ?pos - location)``: A location is occupied, used to avoid overlapping objects during movement actions.
- ``(adjacent ?pos1 ?pos2 - location)``: Two locations are adjacent, used to constrain the range of actions.
- ``(head ?snake - snake ?headpos - location)``: A snake head is at this location, used to constrain the range of actions, updated after every action.
- ``(connected ?snake - snake ?bodypos1 ?bodypos2 - location)``: Two parts of the same snake are at these locations, used to update the snake configuration.
- ``(tail ?snake - snake ?tailpos - location)``: A snake tail is at this location, updated after movement actions.
- ``(mouse-at ?foodpos - location)``: A mouse is at this location, updated after strike actions.

## Actions/Operators
- ``(:action strike :parameters (?snake - snake ?headpos ?foodpos - location))``: represents the mouse being consumed by an adjacent snake head.
- ``(:action move-short :parameters (?snake - snake ?nextpos ?snakepos - location))``: represents single location snake movement.
- ``(:action move-long :parameters  (?snake - snake ?nextpos ?headpos ?bodypos ?tailpos - location))``: represents multiple location snake movement.

Move was split in two to minimize the amount of grounded actions without the use of disjunctions.
The JSHOP version contains explicit ``visit/unvisit`` operators to avoid infinite loops.

## Tasks and Methods
Two tasks are described in the [JSHOP] and [HDDL] versions, with 5 methods in total.
The first task is ``hunt``, with zero parameters, used as the main task.
Two methods are used for this task, a recursive one to select one snake that will strike a mouse, and a base one for no more mice.
The base case is described after the recursive method as it happens only once, when all mice have been consumed.

```
(:task hunt :parameters ())
(:method hunt_all :parameters (?snake - snake ?foodpos ?snakepos ?pos1 - location))
(:method hunt_done :parameters ())
```

The second task is ``move``, with a snake, its head and goal location as parameters.
Here we have a base method and two recursive ones to use the ``move-long`` and ``move-short`` actions.
The ``move-base`` case is described first to avoid redundant expansions in planners that follow the description order.
The ``move-short`` is the last case described as it is less common.

```
(:task move :parameters (?snake - snake ?snakepos ?goalpos - location))
(:method move-base :parameters (?snake - snake ?snakepos ?goalpos - location))
(:method move-long-snake  :parameters (?snake - snake ?snakepos ?goalpos ?pos2 ?bodypos ?tailpos - location))
(:method move-short-snake :parameters (?snake - snake ?snakepos ?goalpos ?pos2 - location))
```

## Problems
Each problem contains snakes and locations as objects.
Each snake must contain at least a head and tail described in the initial state.
If head and tail are on the same location, single location snake, there is no need to ``connect`` snake parts.
Each mouse location must be described in the initial state.
Locations that contain snake parts, mice or walls are ``occupied``.
Locations must be ``adjacent`` to one another to describe possible paths.
Adjacencies are usually symmetrical, ``(adjacent l1 l2) (adjacent l2 l1)``, and grid-based, but are not limited to.

For goal-based planning it may include snakes' final configuration and mice not existing anymore.
For task-based planning it may include movement and hunting tasks.
Due to the possibly large amount of mice, it is recommended to use ``forall`` or ``exist`` to describe a goal state without mice or tasks to hunt every mouse.

### Problem generator
Currently a text representation, like the one from [Sokoban](http://www.sokobano.de/wiki/index.php?title=Level_format), can be used with our problem generator.
Each character in a text file represents one element of the Snake problem in a grid-based scenario:
- <kbd>Space</kbd> as clear location
- <kbd>@</kbd> as snake head location
- <kbd>$</kbd> as snake body location
- <kbd>*</kbd> as mouse location
- <kbd>#</kbd> as wall location

Currently limited to a single snake, snake parts should be ``adjacent`` only to previous and next locations to avoid ambiguity.
Walls are converted to always ``occupied`` locations, but could also be represented as lack of adjacencies to these locations, which would be harder to manually modify later.
Multiple problems in this format are already available, they were manually crafted to generate longer solutions or force certain paths for the snake to be able to strike all mice.

#### Execution
```
ruby pbgenerator.rb type [pb1.snake ... pbN.snake]
```

Convert all ``*.snake`` files in the current folder or the ones provided as arguments according to ``type``, generating ``*.snake.type`` files.
Type includes ``pddl``, ``hddl`` and ``jshop``.

#### Example
```
ruby pbgenerator.rb hddl pb2.snake
```

Content of input ``pb2.snake``
```
*  
  $
  @
```

Content of output ``pb2.snake.hddl``
```
(define (problem pb2)
  (:domain snake)

  (:objects
    viper - snake
    px0y0 px1y0 px2y0
    px0y1 px1y1 px2y1
    px0y2 px1y2 px2y2 - location
  )

  (:init
    (head viper px2y2)
    (connected viper px2y2 px2y1)
    (tail viper px2y1)

    (mouse-at px0y0)

    (occupied px0y0)
    (occupied px2y1)
    (occupied px2y2)

    (adjacent px0y0 px1y0) (adjacent px1y0 px0y0) (adjacent px1y0 px2y0) (adjacent px2y0 px1y0)
    (adjacent px0y1 px1y1) (adjacent px1y1 px0y1) (adjacent px1y1 px2y1) (adjacent px2y1 px1y1)
    (adjacent px0y2 px1y2) (adjacent px1y2 px0y2) (adjacent px1y2 px2y2) (adjacent px2y2 px1y2)

    (adjacent px0y0 px0y1) (adjacent px0y1 px0y0) (adjacent px1y0 px1y1) (adjacent px1y1 px1y0) (adjacent px2y0 px2y1) (adjacent px2y1 px2y0)
    (adjacent px0y1 px0y2) (adjacent px0y2 px0y1) (adjacent px1y1 px1y2) (adjacent px1y2 px1y1) (adjacent px2y1 px2y2) (adjacent px2y2 px2y1)
  )

  (:htn :subtasks (hunt))
)
```

## ToDo's
- Support multiple snakes
- Support snake goal locations
- Random generator

[PDDL]: https://en.wikipedia.org/wiki/Planning_Domain_Definition_Language "PDDL at Wikipedia"
[HDDL]: http://gki.informatik.uni-freiburg.de/papers/hoeller-etal-aaai20.pdf "HDDL paper"
[JSHOP]: https://www.cs.umd.edu/projects/shop/description.html "SHOP/JSHOP project page"