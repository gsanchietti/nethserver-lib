==============
nethserver-lib
==============

This package contains common libraries for all system modules.

Task progress tracking
======================

The system implements an utility called ``ptrack`` which is invoked
from the web interface for handling long running processes like events.

Message format
--------------

Messages between the client and the server have three parts, following a "TLV" structure (http://en.wikipedia.org/wiki/Type-length-value): ::

  [type] [length] [value]

* ``type`` is an unsigned char (1 byte)
* ``length`` is a short integer (2 bytes)
* ``value`` is a string (max length 65535 bytes)

Protocol
--------

The client initiates the conversation by sending one message. Actually there are 4 types of message: ::

    DECLARE  = 0x01
    DONE     = 0x02
    QUERY    = 0x03
    PROGRESS = 0x04

The message payload is actually encoded in JSON syntax. It's an array structure, used as method arguments.  
For instance, a ``DECLARE`` message payload can be set to: ::

    [0, 1.0, "First subtask"] 

The server response type is a bitwise OR of the original request type, RESPONSE and possibly ERROR: ::

    ERROR    = 0x40
    RESPONSE = 0x80

