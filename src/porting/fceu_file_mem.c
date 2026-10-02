/* Minimal FCEUFILE backed by an in-memory buffer (no libretro VFS).
 * Used by the GNW / host builds for UNIF (and any future buffer loaders). */

#include <stdlib.h>
#include <string.h>

#include "fceu-types.h"
#include "file.h"
#include "fceu-endian.h"
#include "fceu-memory.h"

static MEMWRAP *MakeMemWrapBuffer(const uint8 *buffer, size_t bufsize)
{
	MEMWRAP *tmp = (MEMWRAP *)FCEU_malloc(sizeof(MEMWRAP));
	if (!tmp)
		return NULL;
	tmp->location = 0;
	tmp->size = (uint32)bufsize;
	tmp->data_int = NULL;
	tmp->data = buffer;
	return tmp;
}

FCEUFILE *FCEU_fopen(const char *path, const uint8 *buffer, size_t bufsize)
{
	FCEUFILE *fceufp;
	(void)path;
	if (!buffer || bufsize == 0)
		return NULL;
	fceufp = (FCEUFILE *)FCEU_malloc(sizeof(FCEUFILE));
	if (!fceufp)
		return NULL;
	fceufp->fp = MakeMemWrapBuffer(buffer, bufsize);
	if (!fceufp->fp) {
		FCEU_free(fceufp);
		return NULL;
	}
	return fceufp;
}

int FCEU_fclose(FCEUFILE *fp)
{
	if (!fp)
		return 0;
	if (fp->fp) {
		if (fp->fp->data_int)
			FCEU_free(fp->fp->data_int);
		fp->fp->data_int = NULL;
		FCEU_free(fp->fp);
	}
	fp->fp = NULL;
	FCEU_free(fp);
	return 1;
}

uint64 FCEU_fread(void *ptr, size_t element_size, size_t nmemb, FCEUFILE *fp)
{
	uint32_t total = (uint32_t)(nmemb * element_size);

	if (fp->fp->location >= fp->fp->size)
		return 0;

	if ((fp->fp->location + total) > fp->fp->size) {
		uint32_t ak = fp->fp->size - fp->fp->location;
		memcpy((uint8_t *)ptr, fp->fp->data + fp->fp->location, ak);
		fp->fp->location = fp->fp->size;
		return (ak / element_size);
	}

	memcpy((uint8_t *)ptr, fp->fp->data + fp->fp->location, total);
	fp->fp->location += total;
	return nmemb;
}

int FCEU_fseek(FCEUFILE *fp, long offset, int whence)
{
	switch (whence) {
	case SEEK_SET:
		if (offset < 0 || (uint32)offset >= fp->fp->size)
			return -1;
		fp->fp->location = (uint32)offset;
		break;
	case SEEK_CUR:
		if (offset < 0) {
			if ((uint32)(-offset) > fp->fp->location)
				return -1;
			fp->fp->location -= (uint32)(-offset);
		} else if ((fp->fp->location + (uint32)offset) > fp->fp->size) {
			return -1;
		} else {
			fp->fp->location += (uint32)offset;
		}
		break;
	default:
		return -1;
	}
	return 0;
}

int FCEU_read32le(uint32 *Bufo, FCEUFILE *fp)
{
	if ((fp->fp->location + 4) > fp->fp->size)
		return 0;
	*Bufo = FCEU_de32lsb(fp->fp->data + fp->fp->location);
	fp->fp->location += 4;
	return 1;
}

int FCEU_fgetc(FCEUFILE *fp)
{
	if (fp->fp->location < fp->fp->size)
		return fp->fp->data[fp->fp->location++];
	return EOF;
}

uint64 FCEU_ftell(FCEUFILE *fp)
{
	return fp->fp->location;
}

uint64 FCEU_fgetsize(FCEUFILE *fp)
{
	return fp->fp->size;
}
