import React, { useEffect } from "react";
import MessageBox from "../../Shared/MessageBox";
import { Table, Header } from "semantic-ui-react";
import RenderValue from "../../Shared/RenderValue";
import { tableSortReducer } from "../../Shared/TableSort";

const CompanyTimeline = ({ records, searchInput }) => {
  // Load the table reducer with the default records
  const [state, dispatch] = React.useReducer(tableSortReducer, {
    column: null,
    data: records,
    direction: null,
  });
  const { column, data, direction } = state;

  // Filter the results when the
  useEffect(() => {
    // console.log({ records, searchInput });

    let filteredData = [];

    // if the searchinput is empty then store the original records
    // => If there is text then filter it by the searchinput
    if (searchInput.length === "") {
      filteredData = records;
    } else {
      filteredData = records.filter((record) => {
        return Object.values(record)
          .join("")
          .toLowerCase()
          .includes(searchInput);
      });
    }

    // update the data in the table
    dispatch({
      data: filteredData,
      type: "UPDATE_DATA",
      column,
      direction,
    });
  }, [searchInput]);

  // if there is no records in the array after filtering then return message
  if (data.length === 0) {
    return (
      <MessageBox title={"Company"} message={"No records matched search text"} />
    );
  }

  // Return table with records
  return (
    <div className="table-overflow" style={{ marginBottom: "1em" }}>
      <Table unstackable sortable celled striped>
        <Table.Header>
          <Table.Row>
          <Table.HeaderCell
              colSpan="100%"
              style={{ backgroundColor: "#989898" }}
            >
              Company
            </Table.HeaderCell>
          </Table.Row>
        </Table.Header>

        <Table.Header>
          <Table.Row textAlign="center">
            <Table.HeaderCell
              sorted={column === "name" ? direction : null}
              onClick={() => dispatch({ type: "CHANGE_SORT", column: "name" })}
            >
              Name
            </Table.HeaderCell>
          </Table.Row>
        </Table.Header>
        <Table.Body>
          {data.map((record) => {
            return (
              <Table.Row key={record.id} textAlign="center">
                <Table.Cell>
                    <RenderValue value={record.company_name} />
                  </Table.Cell>
              </Table.Row>
            );
          })}
        </Table.Body>
      </Table>
    </div>
  );
};

export default CompanyTimeline;
