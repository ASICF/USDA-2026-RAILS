import React, { useState, useEffect, Fragment } from "react";
import {
  Accordion,
  Breadcrumb,
  Divider,
  Header,
  Icon,
  Input,
  Table,
} from "semantic-ui-react";
import MessageBox from "../../Shared/MessageBox";
import axios from "axios";
import RenderValue from "../../Shared/RenderValue";

function TileStatus(props) {
  console.log("TileStatus", props);
  const [activeIndex, setActiveIndex] = useState(-1);
  const [searchInput, setSearchInput] = useState("");
  const [records, setRecords] = useState(null);
  const [data, setData] = useState();

  // handle row click
  const handleClick = (e, titleProps) => {
    const { index } = titleProps;
    const newIndex = activeIndex === index ? -1 : index;
    setActiveIndex(newIndex);
  };

  // Filters the data based on the serarch input
  useEffect(() => {
    let filteredData = [];

    if (searchInput !== "" && data !== undefined) {
      filteredData = records.filter((record) => {
        return Object.values(record)
          .join("")
          .toLowerCase()
          .includes(searchInput);
      });
    }
    if (filteredData !== undefined) {
      setRecords(filteredData);
    }
  }, [searchInput]);

  // submits query after user starts typing with a delay
  useEffect(() => {
    let inputTimeout;

    if (searchInput !== "") {
      // Clear the timeout if the user keeps typing
      clearTimeout(inputTimeout);

      // Start a half second timeout
      inputTimeout = setTimeout(() => {
        // if the timeout occurs then make the POST request
        axios
          .post("/tile_status/query", {
            poly_id: searchInput,
          })
          .then((response) => {
            setData(response.data);
            console.log(data);
          })
          .catch((error) => {
            console.error(error);
          });
      }, 500);
    }

    // Clear the timeout on unmount
    return () => {
      clearTimeout(inputTimeout);
    };
  }, [searchInput]);

  return (
    <Fragment>
      <Breadcrumb>
        <Breadcrumb.Section>Reports</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>Tile Status</Breadcrumb.Section>
      </Breadcrumb>
      <Divider />

      <Accordion fluid styled>
        <Accordion.Title
          active={activeIndex === 0}
          index={0}
          onClick={handleClick}
        >
          <Icon name="dropdown" />
          Tool Info
        </Accordion.Title>
        <Accordion.Content active={activeIndex === 0}>
          <Divider />
          <Header as="h4">Summary:</Header>
          <p>
            Enter a valid <strong>PolyID</strong> and this report will return
            the Tile Info as well as any intersecting{" "}
            <strong>Footprints, ADS,</strong> and{" "}
            <strong>Frame Centers.</strong>
          </p>
          <Header as="h4">Inputs:</Header>
          <p>
            • A Valid <strong>PolyID</strong> <em>(e.g. 51017_050501R)</em>
          </p>
        </Accordion.Content>
      </Accordion>

      <Divider />
      <Input
        fluid
        styled
        icon={<Icon name="search" inverted circular />}
        placeholder="Search PolyID..."
        onChange={(e) => setSearchInput(e.target.value)}
      />
      <Divider />

      {searchInput !== "" &&
        data != undefined &&
        data.result &&
        data.result.length === 0 && (
          <MessageBox
            title={"No Tile Found"}
            message={"No records matched search text"}
          />
        )}

      {data !== undefined && data.result.length > 0 && (
        <div className="table-overflow no-margin no-padding">
          <Table selectable unstackable celled striped>
            <Table.Header>
              <Table.Row>
                <Table.HeaderCell textAlign="center">Poly ID</Table.HeaderCell>
                <Table.HeaderCell textAlign="center">
                  Project
                </Table.HeaderCell>
                <Table.HeaderCell textAlign="center">
                  County Name
                </Table.HeaderCell>
                <Table.HeaderCell textAlign="center">
                  State Name
                </Table.HeaderCell>
                <Table.HeaderCell textAlign="center">
                  Flight Date
                </Table.HeaderCell>
                <Table.HeaderCell textAlign="center">
                  At Done Date
                </Table.HeaderCell>
                <Table.HeaderCell textAlign="center">
                  Ortho Proc Date
                </Table.HeaderCell>
                <Table.HeaderCell textAlign="center">
                  Ship Date
                </Table.HeaderCell>
                <Table.HeaderCell textAlign="center">
                  Invoice Date
                </Table.HeaderCell>
                <Table.HeaderCell textAlign="center">
                  Accepted Date
                </Table.HeaderCell>
              </Table.Row>
            </Table.Header>
            <Table.Body>
              {data.result.map((data, index) => {
                return (
                  <Table.Row
                    key={index}
                    style={{ cursor: "pointer" }}
                    onClick={() => {
                      window.location.href = `tile_status_render/${data.poly_id}`;
                    }}
                  >
                    <Table.Cell>
                      <RenderValue value={data.poly_id} />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={data.project} />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={data.county_name} />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={data.state_name} />
                    </Table.Cell>
                    <Table.Cell textAlign="center">
                      {data.flight_date === null ? (
                        <Icon name="delete" className="red-delete" />
                      ) : (
                        <Icon name="checkmark" className="green-check" />
                      )}
                    </Table.Cell>
                    <Table.Cell textAlign="center">
                      {data.at_done_date === null ? (
                        <Icon name="delete" className="red-delete" />
                      ) : (
                        <Icon name="checkmark" className="green-check" />
                      )}
                    </Table.Cell>
                    <Table.Cell textAlign="center">
                      {data.ortho_proc_date === null ? (
                        <Icon name="delete" className="red-delete" />
                      ) : (
                        <Icon name="checkmark" className="green-check" />
                      )}
                    </Table.Cell>
                    <Table.Cell textAlign="center">
                      {data.ship_date === null ? (
                        <Icon name="delete" className="red-delete" />
                      ) : (
                        <Icon name="checkmark" className="green-check" />
                      )}
                    </Table.Cell>
                    <Table.Cell textAlign="center">
                      {data.invoiced_date === null ? (
                        <Icon name="delete" className="red-delete" />
                      ) : (
                        <Icon name="checkmark" className="green-check" />
                      )}
                    </Table.Cell>
                    <Table.Cell textAlign="center">
                      {data.usda_accepted_date === null ? (
                        <Icon name="delete" className="red-delete" />
                      ) : (
                        <Icon name="checkmark" className="red-delete" />
                      )}
                    </Table.Cell>
                  </Table.Row>
                );
              })}
            </Table.Body>
          </Table>
        </div>
      )}
    </Fragment>
  );
}

export default TileStatus;
