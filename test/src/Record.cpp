#include <Record.hpp>

Record::Record()
{
    m_data = 0;
}

int Record::getData()
{
    return m_data;
}

void Record::setData(int _data)
{
    m_data = _data;
}
