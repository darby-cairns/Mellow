#ifndef MELLOW_INTERNAL_H
#define MELLOW_INTERNAL_H

#include <stddef.h>
#include <stdint.h>

// mellow-string:
// [uint32_t ref-count, uint32_t string length, len bytes char[], 1 null-byte]

// mellow-maybe:
// [uint32_t ref-count, uint32_t variant tag, max-size of each constructor
//  value tuple]
// Tag 0: Some
// Tag 1: None

#define MELLOW_PTR_SIZE (sizeof(char*))
#define REF_SIZE (4)
#define LEN_SIZE (4)
#define HEAD_SIZE (REF_SIZE + LEN_SIZE)
#define REF_COUNT_SIZE (sizeof(uint32_t))
#define MELLOW_STR_SIZE (sizeof(uint32_t))
#define VARIANT_TAG_SIZE (sizeof(uint32_t))

// Allocate space for a full mellow string, update ref-count to 1, populate
// length field, copy c-string into allocated space for string, add null byte to
// end, and return pointer to beginning of allocated memory for mellow-string
void* mellow_allocString(const char* str, const uint32_t length);
// Make a copy of the string, with a ref-count of 1
void* mellow_copyString(void* str);

// Deallocate all memory allocated by mellow_allocString()
void mellow_freeString(void* mellowString);

void* __arr_arr_append(void* left, void* right,
                       size_t elem_size, uint64_t is_str);

void* __elem_arr_append(uint64_t left, void* right,
                        size_t elem_size, uint64_t is_str);

void* __arr_elem_append(void* left, uint64_t right,
                        size_t elem_size, uint64_t is_str);

void* __elem_elem_append(uint64_t left, uint64_t right,
                         size_t elem_size, uint64_t is_str);

void* __arr_slice(void* arr, uint64_t lindex, uint64_t rindex,
                  uint64_t elem_size, uint64_t is_str);

#endif
