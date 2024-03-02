import React, { useState, Fragment, useEffect } from "react";
import {
  Table,
  Breadcrumb,
  Divider,
  Grid,
  Menu,
  Label,
  Dimmer,
  Loader,
  Segment
} from "semantic-ui-react";
import Breadcrumbs from "../Shared/Breadcrumb";
import axios from "axios";
import _ from "lodash";
import RenderValue from "../Shared/RenderValue";
import MessageBox from "../Shared/MessageBox";
import Calendar from "react-github-contribution-calendar";

function ReportHistory(props) {

  //useStates:
  const [initRecords, setInitRecords] = useState(props.reports);
  const [selectedRecord, setSelectedRecord] = useState(initRecords[0].name);
  const [records, setRecords] = useState();
  const [calendarData, setCalendarData] = useState("");

  // POST first record by default
  useEffect(() => {
    if (initRecords.length > 0) {
      handleRecordClick(initRecords[0].name);
    }
  }, []);
  //onClick POST Logic:
  const handleRecordClick = (recordName) => {
    setSelectedRecord(recordName);

    axios
      .post(`/report_history/`, {
        name: recordName,
        authenticity_token: props.token,
      })
      .then((response) => {
        setRecords(response.data.records);
        setCalendarData(response.data.calendar);
      });
  };

  // Filter the records based on the selected record name
  const filteredRecords = selectedRecord
    ? initRecords.filter((record) => record.name === selectedRecord)
    : initRecords;

  //Change Panel Colors on Heatmap:
  let panelColors = [
    "#e2e0e0",
    "#6D9DC5",
    "#5F94BF",
    "#508AB9",
    "#4680AF",
    "#3d7199",
  ];
  return (
    <div className="no-padding no-margin">
      <Fragment>
        <Breadcrumbs>
          <Breadcrumb.Section>Manage</Breadcrumb.Section>
          <Breadcrumb.Divider />
          <Breadcrumb.Section active>Report History</Breadcrumb.Section>
        </Breadcrumbs>
        <Divider />
      </Fragment>
      <Grid>
        <Grid.Column mobile={16} tablet={8} computer={6}>
          <Menu fluid vertical>
            {/* Filter Alphabetically, make a duplicate to avoid overwriting records */}
            {initRecords
              .sort((a, b) => a.name.localeCompare(b.name))
              .map((record) => {
                return (
                  <Menu.Item
                  key={record.id}
                  name={record.name}
                  active={selectedRecord === record.name}
                  onClick={() => {
                    handleRecordClick(`${record.name}`);
                  }}
                >
                  <RenderValue value={record.name} />
                  {/* Make Label colored when active */}
                  {selectedRecord === record.name ? (
                    <Label color="blue">{record.count}</Label>
                  ) : <Label>{record.count}</Label>}
                </Menu.Item>
                );
              })}
          </Menu>
        </Grid.Column>
        <Grid.Column stackable="true" mobile={16} tablet={8} computer={10}>
          <Segment>
          {calendarData && (
            <Calendar
              values={calendarData.values}
              until={calendarData.until}
              panelColors={panelColors}
            />
          )}
          </Segment>
          {records && (
            <Table unstackable celled striped>
              {!records && (
                <Dimmer active inverted>
                  <Loader inverted>Fetching Data...</Loader>
                </Dimmer>
              )}
              <Table.Header>
                <Table.Row>
                  <Table.HeaderCell textAlign="center">Name</Table.HeaderCell>
                  <Table.HeaderCell textAlign="center">User</Table.HeaderCell>
                  <Table.HeaderCell textAlign="center">
                    Created At
                  </Table.HeaderCell>
                </Table.Row>
              </Table.Header>
              <Table.Body>
                {records.map((record) => {
                  return (
                    <Table.Row
                      style={{ cursor: "pointer" }}
                      key={record.id}
                      textAlign="center"
                    >
                      <Table.Cell>
                        <RenderValue value={record.name} />
                      </Table.Cell>
                      <Table.Cell>
                        <RenderValue value={record.user_name} />
                      </Table.Cell>
                      <Table.Cell>
                        <RenderValue value={record.created_at} date />
                      </Table.Cell>
                    </Table.Row>
                  );
                })}
              </Table.Body>
            </Table>
          )}
        </Grid.Column>
      </Grid>
    </div>
  );
}

export default ReportHistory;
