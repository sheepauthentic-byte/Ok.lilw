//
//  MemoryPatch.cpp
//
//  Created by MJ (Ruit) on 1/1/19.
//

#include "MemoryPatch.hpp"
#include "KittyUtils.hpp"

MemoryPatch::MemoryPatch()
{
  _address = 0;
  _size = 0;
  _orig_code.clear();
  _patch_code.clear();
}

MemoryPatch::~MemoryPatch()
{
  // clean up
  _orig_code.clear();
  _orig_code.shrink_to_fit();

  _patch_code.clear();
  _patch_code.shrink_to_fit();
}

MemoryPatch MemoryPatch::createWithBytes(uintptr_t absolute_address, const void *patch_code, size_t patch_size)
{
  MemoryPatch patch;

  if (!absolute_address || !patch_code || patch_size < 1)
    return patch;

  patch._address = absolute_address;
  patch._size = patch_size;

  patch._orig_code.resize(patch_size);
  patch._patch_code.resize(patch_size);

  // initialize patch & backup current content
  KittyMemory::memRead(patch_code, &patch._patch_code[0], patch_size);
  KittyMemory::memRead(reinterpret_cast<const void *>(patch._address), &patch._orig_code[0], patch_size);
  return patch;
}

MemoryPatch MemoryPatch::createWithHex(uintptr_t absolute_address, std::string hex)
{
  MemoryPatch patch;

  if (!absolute_address || !KittyUtils::String::ValidateHex(hex))
    return patch;

  patch._address = absolute_address;
  patch._size = hex.length() / 2;

  patch._orig_code.resize(patch._size);
  patch._patch_code.resize(patch._size);

  // initialize patch
  KittyUtils::dataFromHex(hex, &patch._patch_code[0]);

  // backup current content
  KittyMemory::memRead(reinterpret_cast<const void *>(patch._address), &patch._orig_code[0], patch._size);
  return patch;
}

MemoryPatch MemoryPatch::createWithBytes(const char *fileName, uintptr_t address, const void *patch_code, size_t patch_size)
{
  if (!address || !patch_code || !patch_size)
    return MemoryPatch();

  uintptr_t absolute_address = KittyMemory::getAbsoluteAddress(fileName, address);
  return createWithBytes(absolute_address, patch_code, patch_size);
}

MemoryPatch MemoryPatch::createWithHex(const char *fileName, uintptr_t address, const std::string &hex)
{
  if (!address || hex.empty())
    return MemoryPatch();

  uintptr_t absolute_address = KittyMemory::getAbsoluteAddress(fileName, address);
  return createWithHex(absolute_address, hex);
}

bool MemoryPatch::isValid() const
{
  return (_address != 0 && _size > 0 && _orig_code.size() == _size && _patch_code.size() == _size);
}

size_t MemoryPatch::get_PatchSize() const
{
  return _size;
}

uintptr_t MemoryPatch::get_TargetAddress() const
{
  return _address;
}

bool MemoryPatch::Restore()
{
  if (!isValid()) return false;

  return KittyMemory::memWrite(reinterpret_cast<void *>(_address), &_orig_code[0], _size) == KittyMemory::KMS_SUCCESS;
#
}

bool MemoryPatch::Modify()
{
  if (!isValid()) return false;

  return KittyMemory::memWrite(reinterpret_cast<void *>(_address), &_patch_code[0], _size) == KittyMemory::KMS_SUCCESS;
}

std::string MemoryPatch::get_CurrBytes() const
{
  if (!isValid()) return "";
  
  return KittyUtils::data2Hex(reinterpret_cast<const void *>(_address), _size);
}

std::string MemoryPatch::get_OrigBytes() const
{
  if (!isValid()) return "";
  
  return KittyUtils::data2Hex( _orig_code.data(), _orig_code.size());
}

std::string MemoryPatch::get_PatchBytes() const
{
  if (!isValid()) return "";
  
  return KittyUtils::data2Hex(_patch_code.data(), _patch_code.size());
}