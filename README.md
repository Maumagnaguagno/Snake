# Snake
**Snake game descriptions for automated planning**

# Domain
Based on the [game genre](https://en.wikipedia.org/wiki/Snake_(video_game_genre)) of the same name, very common among Nokia cellphones.
One or more snakes can either move to clear locations or strike/attack a nearby mice in a grid/graph-based scenario, the mice do not move as they are too afraid.
Each snake occupies one or more adjacent locations due to their long body.
The goal is to hunt all the mice or have the snakes occupying certain positions (which forces them to eat and grow).
Multiple plans may exist in some scenarios due to multiple snakes being able to strike mouses in different orderings using different paths.
Plans contain zero or more movement actions and one strike per mouse in the problem instance.
Differently from the game where usually only one mouse is visible at a time, all mice are visible to give more choice, making problems harder.

## Types
All objects are either ``snake`` or ``location``.
This removes the need to have more objects to define each mouse and snake parts.
Removing such objects make grounding faster due to less parameters and descriptions simpler.
Instead of having ``(at ?mouse ?location)`` we can use ``(mouse-at ?location)`` and remove the ``?mouse`` parameter from the ``strike`` action.
If we had opted for snake parts we would have several ways of describing the same long snake, making an explosion in the state-space.

## Predicates
- ``(occupied ?pos - location)``: A location is occupied, used to avoid overlapping objects during movement actions.
- ``(adjacent ?pos1 ?pos2 - location)``: Two locations are adjacent, used to constrain the range of actions.
- ``(head ?snake - snake ?headpos - location)``: A snake head is at this location, used to constrain the range of actions, updated after every action.
- ``(connected ?snake - snake ?bodypos1 ?bodypos2 - location)``: Two parts of the same snake are at these locations, used to update the snake configuration.
- ``(tail ?snake - snake ?tailpos - location)``: A snake tail is at this location, updated after movement actions.
- ``(mouse-at ?foodpos - location)``: A mouse is at this location, updated after strike actions.

## Actions/Operators
- ``(:action strike :parameters (?snake - snake ?headpos ?foodpos - location))``: represents the mouse being attacked by an adjacent snake head.
- ``(:action move-short :parameters (?snake - snake ?nextpos ?snakepos - location))``: represents movement of single cell snakes.
- ``(:action move-long :parameters  (?snake - snake ?nextpos ?headpos ?bodypos ?tailpos - location))``: represents movement or more than one cell snakes.

The JSHOP version contains explicit ``visit/unvisit`` operators to avoid infinite loops.

## Tasks and Methods
Two tasks are described in the JSHOP and HDDL versions, with 5 methods.
The first task is ``hunt``, with zero parameters, used as the main task.
Two methods are used for this task, a recursive one to select one snake that will attack a mouse, and a base one for no more mice to be attacked.
The base case is described after the recursive as it happens only once, it requires universal preconditions to verify that every location does not contain a mouse.

```
(:task hunt :parameters ())
(:method hunt_all :parameters (?snake - snake ?foodpos ?snakepos ?pos1 - location))
(:method hunt_done :parameters ())
```

The second task is ``move``, with a snake, its head and goal position as parameters.
Here we have a base method and two recursive ones to use the ``move-long`` and ``move-short`` actions.
The ``move-base`` case is described first to avoid redundant expansions in planners that follow the description order.
The ``move-short`` case is described after the ``move-short`` case as it is less common.

``
(:task move :parameters (?snake - snake ?snakepos ?goalpos - location))
(:method move-base :parameters (?snake - snake ?snakepos ?goalpos - location))
(:method move-long-snake  :parameters (?snake - snake ?snakepos ?goalpos ?pos2 ?bodypos ?tailpos - location))
(:method move-short-snake :parameters (?snake - snake ?snakepos ?goalpos ?pos2 - location))
``

# Problems
Currently a text representation, like the one from [Sokoban](http://www.sokobano.de/wiki/index.php?title=Level_format), can be used with our problem generator.
Each character in a text file represents one element of the Snake problem in a grid-based scenario:
- ``Space`` as clear cell
- ``@`` as snake head cell
- ``$`` as snake body cell
- ``*`` as mouse cell
- ``#`` as wall cell

Currently limited to a single snake, snake body cells should be adjacent only to previous and next cells to avoid ambiguity.

## Execution
```
ruby pbgenerator.rb [pb1.snake ... pbN.snake]
```

Convert all ``*.snake`` files in the current folder or the ones provided as arguments.

## Example
```
ruby pbgenerator.rb pb2.snake
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
- Support goal head position
- Random generator
- Support PDDL and JSHOP outputs