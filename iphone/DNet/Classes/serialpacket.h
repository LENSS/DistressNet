/**
 * This file is automatically generated by mig. DO NOT EDIT THIS FILE.
 * This file defines the layout of the 'serial_packet' message type.
 */

#ifndef SPACKET_H
#define SPACKET_H
#include "message.h"

enum {
  /** The default size of this message type in bytes. */
  SPACKET_SIZE = 7,

  /** The Active Message type associated with this message. */
  SPACKET_AM_TYPE = -1,

  /* Field header.dest: type uint16_t, offset (bits) 0, size (bits) 16 */
  /** Offset (in bytes) of the field 'header.dest' */
  SPACKET_HEADER_DEST_OFFSET = 0,
  /** Offset (in bits) of the field 'header.dest' */
  SPACKET_HEADER_DEST_OFFSETBITS = 0,
  /** Size (in bytes) of the field 'header.dest' */
  SPACKET_HEADER_DEST_SIZE = 2,
  /** Size (in bits) of the field 'header.dest' */
  SPACKET_HEADER_DEST_SIZEBITS = 16,

  /* Field header.src: type uint16_t, offset (bits) 16, size (bits) 16 */
  /** Offset (in bytes) of the field 'header.src' */
  SPACKET_HEADER_SRC_OFFSET = 2,
  /** Offset (in bits) of the field 'header.src' */
  SPACKET_HEADER_SRC_OFFSETBITS = 16,
  /** Size (in bytes) of the field 'header.src' */
  SPACKET_HEADER_SRC_SIZE = 2,
  /** Size (in bits) of the field 'header.src' */
  SPACKET_HEADER_SRC_SIZEBITS = 16,

  /* Field header.length: type uint8_t, offset (bits) 32, size (bits) 8 */
  /** Offset (in bytes) of the field 'header.length' */
  SPACKET_HEADER_LENGTH_OFFSET = 4,
  /** Offset (in bits) of the field 'header.length' */
  SPACKET_HEADER_LENGTH_OFFSETBITS = 32,
  /** Size (in bytes) of the field 'header.length' */
  SPACKET_HEADER_LENGTH_SIZE = 1,
  /** Size (in bits) of the field 'header.length' */
  SPACKET_HEADER_LENGTH_SIZEBITS = 8,

  /* Field header.group: type uint8_t, offset (bits) 40, size (bits) 8 */
  /** Offset (in bytes) of the field 'header.group' */
  SPACKET_HEADER_GROUP_OFFSET = 5,
  /** Offset (in bits) of the field 'header.group' */
  SPACKET_HEADER_GROUP_OFFSETBITS = 40,
  /** Size (in bytes) of the field 'header.group' */
  SPACKET_HEADER_GROUP_SIZE = 1,
  /** Size (in bits) of the field 'header.group' */
  SPACKET_HEADER_GROUP_SIZEBITS = 8,

  /* Field header.type: type uint8_t, offset (bits) 48, size (bits) 8 */
  /** Offset (in bytes) of the field 'header.type' */
  SPACKET_HEADER_TYPE_OFFSET = 6,
  /** Offset (in bits) of the field 'header.type' */
  SPACKET_HEADER_TYPE_OFFSETBITS = 48,
  /** Size (in bytes) of the field 'header.type' */
  SPACKET_HEADER_TYPE_SIZE = 1,
  /** Size (in bits) of the field 'header.type' */
  SPACKET_HEADER_TYPE_SIZEBITS = 8,

  /* Field data: type uint8_t[], element size (bits) 8 */
  /** Elementsize (in bytes) of the field 'data' */
  SPACKET_DATA_ELEMENTSIZE = 1,
  /** Elementsize (in bits) of the field 'data' */
  SPACKET_DATA_ELEMENTSIZEBITS = 8,
  /** The number of dimensions in the array 'data'. */
  SPACKET_DATA_NUMDIMENSIONS = 1,
  /** Number of elements in dimension 1 of array 'data'. */
  SPACKET_DATA_NUMELEMENTS_1 = 0,
};

/**
 * Return the value of the field 'header.dest'
 */
uint16_t spacket_header_dest_get(tmsg_t *msg);

/**
 * Set the value of the field 'header.dest'
 */
void spacket_header_dest_set(tmsg_t *msg, uint16_t value);

/**
 * Return the value of the field 'header.src'
 */
uint16_t spacket_header_src_get(tmsg_t *msg);

/**
 * Set the value of the field 'header.src'
 */
void spacket_header_src_set(tmsg_t *msg, uint16_t value);

/**
 * Return the value of the field 'header.length'
 */
uint8_t spacket_header_length_get(tmsg_t *msg);

/**
 * Set the value of the field 'header.length'
 */
void spacket_header_length_set(tmsg_t *msg, uint8_t value);

/**
 * Return the value of the field 'header.group'
 */
uint8_t spacket_header_group_get(tmsg_t *msg);

/**
 * Set the value of the field 'header.group'
 */
void spacket_header_group_set(tmsg_t *msg, uint8_t value);

/**
 * Return the value of the field 'header.type'
 */
uint8_t spacket_header_type_get(tmsg_t *msg);

/**
 * Set the value of the field 'header.type'
 */
void spacket_header_type_set(tmsg_t *msg, uint8_t value);

/**
 * Return the byte offset of an element of array 'data'
 */
size_t spacket_data_offset(size_t index1);

/**
 * Return an element of the array 'data'
 */
uint8_t spacket_data_get(tmsg_t *msg, size_t index1);

/**
 * Set an element of the array 'data'
 */
void spacket_data_set(tmsg_t *msg, size_t index1, uint8_t value);

/**
 * Return the bit offset of an element of array 'data'
 */
size_t spacket_data_offsetbits(size_t index1);

#endif
